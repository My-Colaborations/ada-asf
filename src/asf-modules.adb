-----------------------------------------------------------------------
--  asf-modules -- Application Module and module registry
--  Copyright (C) 2009, 2010, 2011 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with Ada.IO_Exceptions;
with Ada.Unchecked_Deallocation;

with Util.Files;
with Util.Strings;
with Util.Serialize.IO.XML;

with ASF.Modules.Reader;
package body ASF.Modules is

   --  ------------------------------
   --  Receive an event from the event channel
   --  ------------------------------
   procedure Receive_Event (Sub  : in out Module_Subscriber;
                            Item : in Util.Events.Event'Class) is
   begin
      Sub.Module.Receive_Event (ASF.Events.Modules.Module_Event'Class (Item));
   end Receive_Event;

   --  ------------------------------
   --  Get the module name
   --  ------------------------------
   function Get_Name (Plugin : Module) return String is
   begin
      return To_String (Plugin.Name);
   end Get_Name;

   --  ------------------------------
   --  Get the base URI for this module
   --  ------------------------------
   function Get_URI (Plugin : Module) return String is
   begin
      return To_String (Plugin.URI);
   end Get_URI;

   --  ------------------------------
   --  Get the module configuration property identified by the name.
   --  If the configuration property does not exist, returns the default value.
   --  ------------------------------
   function Get_Config (Plugin  : Module;
                        Name    : String;
                        Default : String := "") return String is
   begin
      return Plugin.Config.Get (Name, Default);
   end Get_Config;

   --  ------------------------------
   --  Get the application.
   --  ------------------------------
   function Get_Application (Plugin : in Module)
                             return access ASF.Applications.Main.Application'Class is
   begin
      return Plugin.App;
   end Get_Application;

   --  ------------------------------
   --  Initialize the the module.  This procedure is called by the application when
   --  the module is registered in the application.
   --  ------------------------------
   procedure Initialize (Plugin : in out Module;
                         App    : access ASF.Applications.Main.Application'Class) is
   begin
      Plugin.App := App;
   end Initialize;

   --  ------------------------------
   --  Get the event subscribers for a given event name.
   --  ------------------------------
   function Get_Subscribers (Plugin : in Module;
                             Event  : in String) return String is
      Subscribers : constant String := Plugin.Get_Config ("event.publish." & Event, "");
   begin
      if Subscribers'Length > 0 then
         return Subscribers;
      else
         return Plugin.Get_Config ("event.publish", "");
      end if;
   end Get_Subscribers;

   --  ------------------------------
   --  Send the event to the module
   --  ------------------------------
   procedure Send_Event (Plugin  : in Module;
                         To      : in String;
                         Content : in ASF.Events.Modules.Module_Event'Class) is
      Subscribers : constant String := Plugin.Get_Subscribers (To);
      Target      : Module_Access;
      Last_Pos    : Natural := Subscribers'First;
      Pos         : Natural;
   begin
      while Last_Pos < Subscribers'Last loop
         Pos := Util.Strings.Index (Source => Subscribers,
                                    Char   => ',',
                                    From   => Last_Pos);
         if Pos = 0 then
            Pos := Subscribers'Last + 1;
         end if;
         exit when Last_Pos = Pos;
         Target := Plugin.Find_Module (Subscribers (Last_Pos .. Pos - 1));
         if Target = null then
            Log.Warn ("Event {0} cannot be sent to missing module {1}",
                      To, Subscribers (Last_Pos .. Pos - 1));
            return;
         end if;
         Target.Channel.Post (Content);
         Last_Pos := Pos + 1;
      end loop;
   end Send_Event;

   --  ------------------------------
   --  Receive an event sent by another module with <b>Send_Event</b> method.
   --  ------------------------------
   procedure Receive_Event (Plugin  : in out Module;
                            Content : in ASF.Events.Modules.Module_Event'Class) is
   begin
      null;
   end Receive_Event;

   --  ------------------------------
   --  Find the module with the given name
   --  ------------------------------
   function Find_Module (Plugin : Module;
                         Name   : String) return Module_Access is
   begin
      if Plugin.Registry = null then
         return null;
      end if;
      return Find_By_Name (Plugin.Registry.all, Name);
   end Find_Module;

   --  ------------------------------
   --  Register under the given name a function to create the bean instance when
   --  it is accessed for a first time.  The scope defines the scope of the bean.
   --  bean
   --  ------------------------------
--     procedure Register (Plugin  : in out Module;
--                         Name    : in String;
--                         Handler : in ASF.Beans.Create_Bean_Access;
--                         Scope   : in ASF.Beans.Scope_Type := ASF.Beans.REQUEST_SCOPE) is
--     begin
--        --        ASF.Beans.Register (Plugin.Factory, Name, Handler, Scope);
--        null;  --  SCz todo
--     end Register;

   --  ------------------------------
   --  Register under the given name a function to create the bean instance when
   --  it is accessed for a first time.  The scope defines the scope of the bean.
   --  bean
   --  ------------------------------
   procedure Register (Plugin : in out Module;
                       Name    : in String;
                       Bind    : in ASF.Beans.Class_Binding_Access) is
   begin
      ASF.Beans.Register_Class (Plugin.Factory, Name, Bind);
   end Register;

   --  ------------------------------
   --  Register all the definitions from the module into a main factory.
   --  This operation is called when the module is registered in the application.
   --  ------------------------------
   procedure Register_Factory (Plugin : in Module;
                               Into   : in out ASF.Beans.Bean_Factory) is
   begin
      ASF.Beans.Register (Into, Plugin.Factory);
   end Register_Factory;

   --  ------------------------------
   --  Finalize the module.
   --  ------------------------------
   overriding
   procedure Finalize (Plugin : in out Module) is
      procedure Free is
        new Ada.Unchecked_Deallocation (Object => Util.Events.Channels.Channel'Class,
                                        Name   => Util.Events.Channels.Channel_Access);
   begin
      Free (Plugin.Channel);
   end Finalize;

   --  ------------------------------
   --  Initialize the registry
   --  ------------------------------
   procedure Initialize (Registry : in out Module_Registry;
                         Config   : in ASF.Applications.Config) is
   begin
      Registry.Config := Config;
   end Initialize;

   --  ------------------------------
   --  Register the module in the registry.
   --  ------------------------------
   procedure Register (Registry : in Module_Registry_Access;
                       Plugin   : in Module_Access;
                       Name     : in String;
                       URI      : in String) is
      Paths : constant String := Registry.Config.Get ("app.modules.dir", "./config");
   begin
      Log.Info ("Register module '{0}' under URI '{1}'", Name, URI);

      if Plugin.Registry /= null then
         Log.Error ("Module '{0}' is already attached to a registry", Name);

         raise Program_Error with "Module '" & Name & "' already registered";
      end if;
      Plugin.Registry := Registry;
      Plugin.Name     := To_Unbounded_String (Name);
      Plugin.URI      := To_Unbounded_String (URI);
      Plugin.Subscriber.Module := Plugin;
      Plugin.Registry.Name_Map.Insert (Name, Plugin);
      if URI /= "" then
         Plugin.Registry.URI_Map.Insert (URI, Plugin);
      end if;

      --  Load the module configuration file
      Log.Debug ("Module search path: {0}", Paths);
      declare
         Base  : constant String := Name & ".properties";
         Path  : constant String := Util.Files.Find_File_Path (Base, Paths);
      begin
         Plugin.Config.Load_Properties (Path => Path, Prefix => Name & ".", Strip => True);

      exception
         when Ada.IO_Exceptions.Name_Error =>
            Log.Warn ("Module configuration file '{0}' does not exist", Path);
      end;

      --  Override the module configuration with the application configuration
      Plugin.Config.Copy (From => Registry.Config, Prefix => Name & ".", Strip => True);

      --  Configure the event channels for this module
      declare
         Kind : constant String := Plugin.Config.Get ("channel.type", "direct");
      begin
         Plugin.Channel := Util.Events.Channels.Create (Name, Kind);
         Plugin.Channel.Subscribe (Plugin.Subscriber'Access);
      end;

      --  Read the module XML configuration file if there is one.
      declare
         Base : constant String := Plugin.Config.Get ("config", Name & ".xml");
         Path : constant String := Util.Files.Find_File_Path (Base, Paths);
      begin
         ASF.Modules.Reader.Read_Configuration (Plugin.all, Path);

      exception
         when Ada.IO_Exceptions.Name_Error =>
            Log.Warn ("Module configuration file '{0}' does not exist", Path);
      end;

   exception
      when Constraint_Error =>
         Log.Error ("Another module is already registered "
                    & "under name '{0}' or URI '{1}'", Name, URI);
         raise;
   end Register;

   --  ------------------------------
   --  Find the module with the given name
   --  ------------------------------
   function Find_By_Name (Registry : Module_Registry;
                          Name     : String) return Module_Access is
      Pos : constant Module_Maps.Cursor := Module_Maps.Find (Registry.Name_Map, Name);
   begin
      if Module_Maps.Has_Element (Pos) then
         return Module_Maps.Element (Pos);
      end if;
      return null;
   end Find_By_Name;

   --  ------------------------------
   --  Find the module mapped to a given URI
   --  ------------------------------
   function Find_By_URI (Registry : Module_Registry;
                         URI      : String) return Module_Access is
      Pos : constant Module_Maps.Cursor := Module_Maps.Find (Registry.URI_Map, URI);
   begin
      if Module_Maps.Has_Element (Pos) then
         return Module_Maps.Element (Pos);
      end if;
      return null;
   end Find_By_URI;

end ASF.Modules;
