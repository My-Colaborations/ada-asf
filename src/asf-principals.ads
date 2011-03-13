-----------------------------------------------------------------------
--  asf-principals -- Component and tag factory
--  Copyright (C) 2011 Stephane Carrez
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

package ASF.Principals is

   --  ------------------------------
   --  Principal
   --  ------------------------------
   type Principal is limited interface;
   type Principal_Access is access all Principal'Class;

   --  Get the principal name.
   function Get_Name (From : in Principal) return String is abstract;

end ASF.Principals;
