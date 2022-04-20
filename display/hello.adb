with Interfaces.C.Strings;  use Interfaces.C.Strings;
with Interfaces.C;          use Interfaces.C;
with GNAT.Strings;          use GNAT.Strings;
with GNAT.OS_Lib;           use GNAT.OS_Lib;

with Ada.Text_IO;      use Ada.Text_IO;
with System;           use System;
with Display;          use Display;

with GL_Gl_H;          use GL_Gl_H;
with SDL_SDL_h;        use SDL_SDL_h;
with SDL_SDL_stdinc_h; use SDL_SDL_stdinc_h;
with SDL_SDL_video_h;  use SDL_SDL_video_h;
with SDL_SDL_events_h; use SDL_SDL_events_h;
with SDL_SDL_timer_h;  use SDL_SDL_timer_h;
with SDL_SDL_keysym_h; use SDL_SDL_keysym_h;
with SDL_SDL_ttf_h;    use SDL_SDL_ttf_h;

procedure Hello is
   surface : access SDL_Surface;
   vidInfo : access SDL_VideoInfo;
   
   w       : constant Integer := 400;
   h       : constant Integer := 400;

   bpp   : constant Interfaces.C.int := 16;
   flags : constant Interfaces.C.unsigned := SDL_OPENGL + SDL_HWSURFACE + SDL_RESIZABLE;
   
   Stop : Boolean := False;
   
   -- Window_Width, Window_Height : Integer;
   
   type Key_Type is new Integer;

   Last_Key : Key_Type with Atomic;
   --  a shared variable, set concurrently by the Poll_Events routine and read
   --  by client code

   procedure Check (Ret : Int) is
   begin
      if Ret /= 0 then
         raise Display_Error;
      end if;
   end Check;
   
   procedure Set_SDL_Video is
   begin
      --  To center a non-fullscreen window we need to set an environment
      --  variable

      Check (SDL_putenv(New_String ("SDL_VIDEO_CENTERED=center")));

      --  the video info structure contains the current video mode. Prior to
      --  calling setVideoMode, it contains the best available mode
      --  for your system. Post setting the video mode, it contains
      --  whatever values you set the video mode with.
      --  First we point at the SDL structure, then test to see that the
      --  point is right. Then we copy the data from the structure to
      --  the safer vidInfo variable.

      declare
         ptr  : System.Address := SDL_GetVideoInfo;
         for ptr'Address use vidInfo'Address;
      begin
         if ptr = System.Null_Address then
            Put_Line ("Error querying video info");
            SDL_SDL_h.SDL_Quit;
            return;
         end if;
      end;

      --  according to the SDL documentaion, the flags parameter passed to setVideoMode
      --  affects only the 2D SDL surface, not the openGL. To set their properties
      --  use the syntax below. We enable vsync because we are running the loop
      --  unfettered and we don't want the loop redrawing the buffer
      --  while it is being written to screen

      Check (SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1));--enable vsync
      Check (SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8));
      Check (SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8));
      Check (SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8));
      Check (SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16));
      Check (SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1));
      Check (SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2));
      Check (SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1));

      --  the setVideoMode function returns the current frame buffer as an
      --  SDL_Surface. Again, we grab a pointer to it, then place its
      --  content into the non pointery surface variable. I say 'non-pointery',
      --  but this SDL variable must have a pointer in it because it can
      --  access the current pixels in the framebuffer.

      surface := SDL_SetVideoMode(int (W), int (H), bpp, flags);

      if surface = null then
         Put_Line ("Error setting the video mode");
         SDL_SDL_h.SDL_Quit;
         return;
      end if;
      
      -- Reset the env. variables to avoid a "runnaway window" syndrome:
      Check (SDL_unsetenv(New_String ("SDL_VIDEO_WINDOW_POS")));
      Check (SDL_unsetenv(New_String ("SDL_VIDEO_CENTERED")));
   
   end Set_SDL_Video;
   
   procedure Poll_Events is
      Evt : aliased SDL_Event;

   begin
      while SDL_PollEvent (Evt'Unchecked_Access) /= 0 loop
         case unsigned (Evt.c_type) is
            
            when SDL_SDL_events_h.SDL_Quit =>
               Stop := True;
               
            when SDL_KEYDOWN =>
               if Evt.Key.Keysym.Sym = SDLK_ESCAPE then
                  Stop := True;
               end if;

            when SDL_KEYUP =>
               Last_Key := 0;

            when SDL_VIDEORESIZE =>
               -- Reshape (Integer (Evt.resize.w), Integer (Evt.resize.h));
               declare
                  Old_Surface : access SDL_Surface := surface;
               begin
                  surface := SDL_SetVideoMode(int (Evt.resize.w), int (Evt.resize.h), bpp, flags);
                  SDL_FreeSurface (Old_Surface);
                  
                  if surface = null then
                     Put_Line ("Error setting the video mode");
                     SDL_SDL_h.SDL_Quit;
                     return;
                  end if;
               end;
               
            when others =>
               null;
         end case;
      end loop;
   end Poll_Events;

begin
   if SDL_Init(SDL_INIT_VIDEO) < 0 then
      Put_Line ("Error initializing SDL");
      SDL_SDL_h.SDL_Quit;
   end if;
   
   Set_SDL_Video;
   
   while not Stop loop
      -- Idle;
      Poll_Events;

      -- glFlush;
      SDL_GL_SwapBuffers;
      SDL_Delay (1);
   end loop;
   
   SDL_SDL_h.SDL_Quit;
   GNAT.OS_Lib.OS_Exit (0);   
end Hello;
