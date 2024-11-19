with Display;                   use Display;
with Display.Basic;             use Display.Basic;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;
with Ada.Command_Line;          use Ada.Command_Line;

procedure N_Bouncing_Balls is
   
   type Ball_Type is record
      Shape  : Shape_Id;
      Dx, Dy : Float;
   end record;
   
   type Ball_Array is array (Integer range <>) of Ball_Type;     
   
   Seed : Generator;

   procedure Iterate (V : in out Ball_Type) is
   begin
      if Get_X (V.Shape) not in -100.0 .. 100.0 then 
         V.Dx := -V.Dx;
      end if;
      
      if Get_Y (V.Shape) not in -100.0 .. 100.0 then 
         V.Dy := -V.Dy;
      end if;
      
      Set_X (V.Shape, Get_X (V.Shape) + V.Dx);
      Set_Y (V.Shape, Get_Y (V.Shape) + V.Dy);
   end Iterate;
   
   N_Balls : Integer := 10;
   
begin
   
   if Argument_Count > 0 then
      N_Balls := Integer'Value (Argument (1));
   end if;
   
   declare
      Balls : Ball_Array (1 .. N_Balls) :=
        (others =>      
           (Shape => New_Circle (0.0, 0.0, 10.0, Blue),
            Dx    => (Random (Seed) * 0.05 + 0.02) * (if Random (Seed) > 0.5 then 1.0 else -1.0),
            Dy    => (Random (Seed) * 0.05 + 0.02) * (if Random (Seed) > 0.5 then 1.0 else -1.0)));
   begin
      loop
         for B of Balls loop 
            Iterate (B);
         end loop;
      
         delay 0.0001;
      end loop;
   end;
   
end N_Bouncing_Balls;
