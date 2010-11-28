-----------------------------------------------------------------------
--  components-root -- ASF Root View Component
--  Copyright (C) 2010 Stephane Carrez
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
with Ada.Finalization;
limited with ASF.Components.Base;
package ASF.Components.Root is

   type UIViewRoot is private;

   --  Get the root node of the view.
   function Get_Root (UI : in UIViewRoot) return access ASF.Components.Base.UIComponent'Class;

   --  Set the root node of the view.
   procedure Set_Root (UI   : in out UIViewRoot;
                       Root : access ASF.Components.Base.UIComponent'Class);

private

   type Root_Holder is limited record
      Ref_Counter : Natural;
      View        : access ASF.Components.Base.UIComponent'Class;
   end record;
   type Root_Holder_Access is access all Root_Holder;

   type UIViewRoot is new Ada.Finalization.Controlled with record
      Root : Root_Holder_Access;
   end record;

   --  Increment the reference counter.
   overriding
   procedure Adjust (Object : in out UIViewRoot);

   --  Free the memory held by the component tree.
   overriding
   procedure Finalize (Object : in out UIViewRoot);

end ASF.Components.Root;
