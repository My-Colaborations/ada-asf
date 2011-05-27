-----------------------------------------------------------------------
--  asf-modules-beans -- Module beans factory
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

package body ASF.Modules.Beans is

   --  Register under the given name a function to create the bean instance when
   --  it is accessed for a first time.  The scope defines the scope of the bean.
   --  bean
   procedure Register (Plugin  : in out Module'Class;
                       Name    : in String;
                       Handler : in Create_Bean_Access;
                       Scope   : in ASF.Beans.Scope_Type := ASF.Beans.REQUEST_SCOPE) is
      Binding : constant Module_Binding_Access
        := new Module_Binding '(Module  => Plugin'Unchecked_Access,
                                Create  => Handler,
                                Scope   => Scope);
   begin
      Plugin.Register (Name, Binding.all'Access);
   end Register;

   --  ------------------------------
   --  Binding record
   --  ------------------------------

   --
   procedure Create (Factory : in Module_Binding;
                     Name    : in Ada.Strings.Unbounded.Unbounded_String;
                     Result  : out Util.Beans.Basic.Readonly_Bean_Access;
                     Scope   : out ASF.Beans.Scope_Type) is
      pragma Unreferenced (Name);
   begin
      Result := Factory.Create.all (Factory.Module);
      Scope  := Factory.Scope;
   end Create;

end ASF.Modules.Beans;
