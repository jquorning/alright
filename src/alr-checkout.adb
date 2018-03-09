with Ada.Directories;

with Alire;
with Alire.Releases;
with Alire.Roots;

with Alr.Files;
with Alr.OS_Lib;
with Alr.Origins;
with Alr.Templates;

package body Alr.Checkout is

   --------------
   -- Checkout --
   --------------

   procedure Checkout (R             : Alire.Releases.Release;
                       Parent_Folder : String;
                       Was_There     : out Boolean)
   is
      use Alr.OS_Lib.Paths;
      Folder : constant String := Parent_Folder / R.Unique_Folder;
   begin
      if Ada.Directories.Exists (Folder) then
         Was_There := True;
         Trace.Detail ("Skipping checkout of already available " & R.Milestone.Image);
      else
         Was_There := False;
         Trace.Detail ("About to check out " & R.Milestone.Image);
         Alr.Origins.Fetch (R.Origin, Folder);
      end if;
   end Checkout;

   ---------------
   -- To_Folder --
   ---------------

   procedure To_Folder (Projects : Query.Instance;
                        Parent   : String := Hardcoded.Projects_Folder;
                        But      : Alire.Name_String := "")
   is
      Was_There : Boolean;
   begin
      for R of Projects loop
         if R.Project /= But then
            Checkout (R, Parent, Was_There);
         end if;
      end loop;
   end To_Folder;

   ------------------
   -- Working_Copy --
   ------------------

   procedure Working_Copy (R              : Alire.Index.Release;
                           Deps           : Query.Instance;
                           Parent_Folder  : String;
                           Generate_Files : Boolean := True;
                           If_Conflict    : Policies := Skip)
     				--  FIXME policies not implemented
   is
      Project : constant Alire.Name_String := R.Project;
      Root    : Alire.Index.Release renames R;
      Was_There : Boolean with Unreferenced;
   begin
      if If_Conflict /= Skip then
         raise Program_Error with "Unimplemented";
      end if;

      Checkout (R, Parent_Folder, Was_There);

      --  And generate its working files, if they do not exist
      if Generate_Files then
         declare
            use OS_Lib;
            Guard      : Folder_Guard    := Enter_Folder (Root.Unique_Folder) with Unreferenced;
            Index_File : constant String := Files.Locate_Index_File (Project);
         begin
            if Index_File = "" then
               Templates.Generate_Prj_Alr (Deps, Alire.Roots.New_Root (Root));
            end if;

            Templates.Generate_Agg_Gpr (Deps, Alire.Roots.New_Root (Root));
         end;
      end if;
   end Working_Copy;

end Alr.Checkout;
