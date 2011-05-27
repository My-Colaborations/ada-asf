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

with Ada.Strings.Unbounded;
with ASF.Beans;
with Util.Beans.Basic;
generic
   type Module is new ASF.Modules.Module with private;
   type Module_Access is access all Module'Class;
package ASF.Modules.Beans is

   --  Create a bean.  The module instance is passed as parameter.
   type Create_Bean_Access is access function (Manager : Module_Access)
                                               return Util.Beans.Basic.Readonly_Bean_Access;

   --  Register under the given name a function to create the bean instance when
   --  it is accessed for a first time.  The scope defines the scope of the bean.
   --  bean
   procedure Register (Plugin  : in out Module'Class;
                       Name    : in String;
                       Handler : in Create_Bean_Access;
                       Scope   : in ASF.Beans.Scope_Type := ASF.Beans.REQUEST_SCOPE);

private
   --  ------------------------------
   --  Binding record
   --  ------------------------------
   type Module_Binding is new ASF.Beans.Binding with record
      Module : Module_Access;
      Scope  : ASF.Beans.Scope_Type;
      Create : Create_Bean_Access;
   end record;
   type Module_Binding_Access is access all Module_Binding;

   --
   procedure Create (Factory : in Module_Binding;
                     Name    : in Ada.Strings.Unbounded.Unbounded_String;
                     Result  : out Util.Beans.Basic.Readonly_Bean_Access;
                     Scope   : out ASF.Beans.Scope_Type);
end ASF.Modules.Beans;
