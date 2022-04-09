private with Alire_Early_Elaboration;
pragma Unreferenced (Alire_Early_Elaboration);

with Alire.Crates.Containers;
with Alire.Dependencies;
with Alire.Origins;
with Alire.Policies;
with Alire.Properties;
with Alire.Releases.Containers;

with Semantic_Versioning.Extended;

package Alire.Index is

   Community_Host : constant String := "https://github.com";

   Community_Organization : constant String := "alire-project";

   Community_Repo_Name : constant String := "alire-index";

   Community_Repo : constant URL :=
                      "git+" & Community_Host
                      & "/" & Community_Organization
                      & "/" & Community_Repo_Name;
   --  Default index installed on first run

   Community_Name : constant Restricted_Name := "community";

   --  We have two sets of branches in the alire-index repo:
   --  devel-x.x.x and stable-x.x.x

   --  Stable alr use a stable-x.x.x (might be shared across alr versions, if
   --  no changes to the index format are necessary). The development versions
   --  of alr may branch out from the latest stable- to a devel- branch for
   --  breaking changes.

   subtype Branch_String is String with Dynamic_Predicate =>
     Branch_String (Branch_String'First) /= '-'
     and then Branch_String (Branch_String'Last) /= '-'
     and then (for some C of Branch_String => C = '-');

   Community_Branch : constant String := "stable-1.1";
   --  The branch used for the community index. Must be updated when new index
   --  features are introduced.

   Min_Compatible_Version : constant String := "1.0.9";
   --  1.0.9 never existed, but this way we can test old index compatibility

   Max_Compatible_Version : constant String :=
                              AAA.Strings.Tail (Community_Branch, '-');

   --  We store here the indexes we are able to load. As long as we do not
   --  break back compatibility, we can keep on simply updating the minor value
   Valid_Versions : constant Semantic_Versioning.Extended.Version_Set :=
                        Semantic_Versioning.Extended.Value
                          ("^" & Min_Compatible_Version
                           & " & <=" & Max_Compatible_Version);

   Version : constant Semantic_Versioning.Version :=
                      Semantic_Versioning.New_Version (Max_Compatible_Version);
   --  The index version understood by alire must match the one in the indexes
   --  being loaded.

   Branch_Kind : constant String := AAA.Strings.Head (Community_Branch, "-");

   subtype Release is Alire.Releases.Release;

   ------------------------
   --  INDEX POPULATION  --
   ------------------------

   procedure Add (Crate  : Crates.Crate;
                  Policy : Policies.For_Index_Merging :=
                    Policies.Merge_Priorizing_Existing);

   procedure Add (Release : Releases.Release;
                  Policy : Policies.For_Index_Merging :=
                    Policies.Merge_Priorizing_Existing);

   procedure Detect_All_Externals (Env : Properties.Vector);
   --  Goes over the list of crates and applies external detection, indexing
   --  any found externals. This has effect only the first time it is called.

   procedure Detect_Externals (Name : Crate_Name; Env : Properties.Vector);
   --  Add only the externals of this crate. This has effect only the first
   --  time it is called for a crate.

   procedure Register_External_Alias (Provider  : Crate_Name;
                                      Providing : Crate_Name);
   --  Register that Provider has external detectors for Providing

   ---------------------
   --  BASIC QUERIES  --
   ---------------------

   function Crate (Name : Crate_Name) return Crates.Crate
     with Pre =>
       Exists (Name) or else
       raise Checked_Error with "Requested crate not in index: " & (+Name);

   function Exists (Name : Crate_Name) return Boolean;

   function Exists (Name : Crate_Name;
                    Version : Semantic_Versioning.Version)
                    return Boolean;

   function Has_Externals (Name : Crate_Name) return Boolean;

   function Releases_Satisfying (Dep              : Dependencies.Dependency;
                                 Env              : Properties.Vector;
                                 Use_Equivalences : Boolean := True;
                                 Available_Only   : Boolean := True;
                                 With_Origin      : Origins.Kinds_Set :=
                                   (others => True))
                                 return Releases.Containers.Release_Set;
   --  Return all releases in the catalog able to provide this dependency,
   --  also optionally considering their "provides" equivalences, and also
   --  optionally including unavailable on the platform.

   function Find (Name    : Crate_Name;
                  Version : Semantic_Versioning.Version) return Release
     with Pre =>
       Exists (Name, Version) or else
     raise Checked_Error with
       "Requested milestone not in index: "
       & (+Name) & "=" & Semantic_Versioning.Image (Version);

   --  Counts

   function Crate_Count return Natural;

   function Release_Count return Natural;

   --  Direct access. TODO: instead of storing a hidden global catalog, make it
   --  a proper type to be returned and manipulated via the functions in this
   --  package.

   function All_Crates return access constant Crates.Containers.Maps.Map;

end Alire.Index;
