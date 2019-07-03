(** A GUI Library for Ocaml

 Entirely written in {{:https://ocaml.org/}ocaml} except for the hardware
   accelerated graphics library {{:https://www.libsdl.org/}SDL2}.

    @version 1907 @author Vu Ngoc San

*)

(* ---------------------------------------------------------------------------- *)

(** Utilities

    This module contains several utilities, in particular for debug logs.
    
{R {{:graph-b_utils.html}Dependency graph}}
*)
module Utils : sig

  (** {2 Debugging} *)

  val printd : int -> ('a, unit, string, unit) format4 -> 'a
  (** For instance [printd debug_warning "The value x=%u is too big" x] will
     print a message in the console only if the {!debug} variable contains the
     [debug_warning] flag. *)

  val debug : bool ref
  val debug_code : int ref
  (** Logical {e ored} of [!debug] with debug flags (below) controls the amount
     of debuging. *)

  (** {3 Binary masks (=flags) for debugging messages.} *)

  val debug_thread : int
  val debug_warning : int
  val debug_graphics : int
  val debug_error : int
  val debug_io : int
  val debug_memory : int
  val debug_board : int
  val debug_event : int
  val debug_custom : int
    
  (** {2 Maths} *)

  val pi : float
    
  val round : float -> int
  (** Round float to nearest integer. *)

  val imax : int -> int -> int
  (** [imax a b] returns max(a,b) *)

  val imin : int -> int -> int
    
  (** {2 Tsdl Result} *)
    
  val go : ('a, 'b) result -> 'a
  (** Transform a [result] into a standard value, or fail with an error. Used
      only for SDL functions. *)

  (** {2 Options}

      Monadic style operations on optional variables. *)

  val map_option : 'a option -> ('a -> 'b) -> 'b option

  val do_option : 'a option -> ('a -> unit) -> unit

  val default : 'a option -> 'a -> 'a

  exception None_option
    
  val remove_option : 'a option -> 'a
  (** Warning: [remove_option None] will raise the {!None_option} exception. *)

  (** {2 Others} *)

  val run : (unit -> 'a) -> 'a
  (**  [run f] is equivalent to [f ()]. *)
    
end (* of Utils *)

(* ---------------------------------------------------------------------------- *)

(** Theming variables

{R {{:graph-b_theme.html}Dependency graph}}
*)
module Theme : sig

  val room_margin : int
    
end (* of Theme *)

(* ---------------------------------------------------------------------------- *)

(** Time in msec 

{R {{:graph-b_time.html}Dependency graph}}
*)
module Time : sig
  type t = int

  val now : unit -> t
  (** Time elapsed from the initialization of SDL (roughly, since the start of
      your program). *)
    
  val adaptive_fps : int -> (unit -> unit) * (unit -> unit)
  (** Create helper functions to help controlling the frame rate of the graphics
     loop. This is only useful if you have your own graphics loop, and do not
     use {!Main.run}.

     [adaptive_fps 60] returns two functions [start,fps]. The statement [start
     ()] will start the timing. At each iteration of your loop, you should call
     [fps ()], which will try to sleep long enough to achieve the desired 60FPS
     rate. It works on average: if some frames take longer, it will shorten the
     next frame to keep up. However, it tries to be nice to the CPU: even if one
     is really too slow, it will guarantee a 5ms sleep to the CPU and {e not}
     try to keep up. *)
                                             
end (* of Time *)

(* ---------------------------------------------------------------------------- *)

(** Global variables with mutex 

{R {{:graph-b_var.html}Dependency graph}}
*)
module Var : sig
  type 'a t

  val create : 'a -> 'a t
  val get :  'a t ->  'a
  val set : 'a t ->  'a -> unit
  
end (* of Var *)

(* ---------------------------------------------------------------------------- *)

(** Delayed actions 

{R {{:graph-b_timeout.html}Dependency graph}}
*)
module Timeout : sig
  type t

  val add : int -> (unit -> unit) -> t
  (** Register a new timeout and return it. [add delay action] will execute
     [action ()] after the delay of [delay] ms. *)
end (* of Timeout *)

(* ---------------------------------------------------------------------------- *)

(** Dealing with events

Events are simply SDL events, plus a few additional events. They are also used
   for primitive communication between threads. 

{R {{:graph-b_trigger.html}Dependency graph}}
 *)
module Trigger : sig
  type t = Tsdl.Sdl.event_type

  val startup : t
  val mouse_enter : t
  val mouse_leave : t
  val var_changed : t
  (** The var_changed event can be send to notify that some widget made a change
      to a global variable. *)

  val update : t
  (** Currently the [update] event is more or less equivalent to
     [var_changed]. This might change in future versions. *)

  val buttons_down : t list
  val buttons_up : t list
  val pointer_motion : t list

  val should_exit : Tsdl.Sdl.event -> bool
  (** Tell if the current thread should exit. This should only be called within
     a widget action. We communicate via the event to decide if the thread
     should exit. *)
  (* à déplacer dans Widget/connection ? *)

  val will_exit : Tsdl.Sdl.event -> unit
  (** A nice thread should do this just before terminating. May be suppressed in
      future versions. *)

  val nice_delay : Tsdl.Sdl.event -> float -> unit
  (** [nice_delay ev t] Wait during a delay ([t] seconds), but quit anyway when
     [{!should_exit} ev] is true. *)

  val push_quit : unit -> unit
  (** Send the SDL_QUIT event, as if the user clicked on the close button of the
     last existing window. It will in principle raise the {!Main.Exit}
     exception and hence exit the mainloop. *)
    
  val event_kind : Tsdl.Sdl.event ->
[ `App_did_enter_background
| `App_did_enter_foreground
| `App_low_memory
| `App_terminating
| `App_will_enter_background
| `App_will_enter_foreground
| `Clipboard_update
| `Controller_axis_motion
| `Controller_button_down
| `Controller_button_up
| `Controller_device_added
| `Controller_device_remapped
| `Controller_device_removed
| `Dollar_gesture
| `Dollar_record
| `Drop_file
| `Finger_down
| `Finger_motion
| `Finger_up
| `Joy_axis_motion
| `Joy_ball_motion
| `Joy_button_down
| `Joy_button_up
| `Joy_device_added
| `Joy_device_removed
| `Joy_hat_motion
| `Key_down
| `Key_up
| `Mouse_button_down
| `Mouse_button_up
| `Mouse_motion
| `Mouse_wheel
| `Multi_gesture
| `Quit
| `Sys_wm_event
| `Text_editing
| `Text_input
| `Unknown of int
| `User_event
| `Window_event ]

end (* of Trigger *)

(* ---------------------------------------------------------------------------- *)

(** Basic audio mixer for sound effects

{R {{:graph-b_mixer.html}Dependency graph}}
 *)
module Mixer : sig
  type t
  type sound =  (int, Bigarray.int16_signed_elt) Tsdl.Sdl.bigarray
  type repeat = Repeat of int | Forever
  (* How many times we should repeat the sound. *)
  
  val test : unit -> unit

  val init : unit -> string option
  (** Initialize SDL audio. @return the name of the audio driver. *)

  val create_mixer : ?tracks:int -> ?freq:int -> string option -> t
  (** Create the mixer an open sound device. Only [s16le] format is supported by
      the callback at this time. *)

  val load_chunk : t -> string -> sound
  (** Load a WAV file. *)

  val play_chunk : ?track:int ->
    ?effects:(sound -> unit) list ->
    ?volume:float -> ?repeat:repeat -> t -> sound -> int option
  (** Play chunk on the desired track number. If [track] is not specified, find
     an available track. By default [repeat = Repeat 1]. @return chosen track
      number, or None *)
      
  val free_chunk : sound -> unit
    
  val change_volume : float -> sound -> unit
  (** Multiply sound intensity by a float factor *)

  val pause : t -> unit
  val unpause : t -> unit
  val close : t -> unit

end (* of Mixer *)

(* ---------------------------------------------------------------------------- *)

(** Synchronized execution queue FIFO queue of actions to be executed by the
   main thread at each graphical frame. It is much easier to use this rather
   than letting actions be executed by various threads and try to guess in which
   order...

{R {{:graph-b_sync.html}Dependency graph}} *)
module Sync : sig

  val push : (unit -> unit) -> unit
  (** Register a action to be executed by the mainloop at next frame, or at a
     subsequent frame if the queue is already large. *)
    
end (* of Sync *)

(* ---------------------------------------------------------------------------- *)

(** Low-level graphics 

{R {{:graph-b_draw.html}Dependency graph}}
*)
module Draw: sig
  type canvas
  (** Contains the hardware information for drawing (SDL renderer and window). *)
    
  type texture = Tsdl.Sdl.texture
  type align =
    | Min
    | Center
    | Max

  (** {2 Initialization and shutdown} *)

  val quit : unit -> unit
  (** Cleanup and quit SDL. *)
    
  (** {2 Colors} *)

  type rgb = int * int * int
  (** red, green and blue values are integers in the range [0..255] *)

  type color = int * int * int * int
  (** r,g,b,a *)

  type fill =
    | Pattern of texture
    | Solid of color

  (** {3 Predefined colors} *)
      
  val black : rgb
  val grey : rgb
  val pale_grey : rgb
  val dark_grey : rgb
  val white : rgb
  val red : rgb
  val blue : rgb
  val green : rgb
  val magenta : rgb
  val cyan : rgb
  val yellow : rgb
  val sienna : rgb

  val label_color : rgb
    
  val none : color
  (** [none = (0,0,0,0)] is completely transparent black. *)

  (** {3 Creating colors} *)
    
  val opaque : rgb -> color
  val transp : rgb -> color
  val lighter : color -> color
  val darker : color -> color
  val set_alpha : int -> rgb -> color
  val find_color : string -> rgb
  (** Convert a string of the form ["grey"] or ["#FE01BC"] to a rgb code
     [(r,g,b)]. Color names are taken from
     {{:https://www.rapidtables.com/web/color/html-color-codes.html}here}. *)

  val pale : rgb -> rgb

  (** {3 Using colors} *)

  val set_color : Tsdl.Sdl.renderer -> color -> unit
  (** Equivalent to [Sdl.set_render_draw_color] *)
  
  (** {2 Layers} *)

  (** Layers are used to decide the order of drawing: which graphical elements
     (layouts) should be below, which should be above. For the most part, you
     don't have to access them directly. *)
  type layer

  val use_new_layer : unit -> unit
  (** Use this when you want to switch to a completely different set of layers,
      typically when you want to draw on another window. *)

  (** {2 SDL misc} *)

  val unscale_size : int * int -> int * int
  (** Transform a size (W,H) in physical pixels into 'logical' pixels (w,h),
      which are used for layouts. *)
                                 
  val set_system_cursor : Tsdl.Sdl.System_cursor.t -> unit
    
end (* of Draw *)

(* ---------------------------------------------------------------------------- *)

(** Mouse information 

{R {{:graph-b_mouse.html}Dependency graph}}
*)
module Mouse : sig
  val pos : unit -> int * int
  (** Get current mouse position *)
                    
end (* of Mouse *)

(* ---------------------------------------------------------------------------- *)

  
(** Transform variables

    Transform variables are a way to share a common data between two widgets,
   when the data has a different meaning (or even a different type) for each
   widget. One widget holds the original value, and the other widget needs to
   apply a {e transformation} each time it wants to read or modify the value.

    For instance you want to share a bank account [b] between Alice in France
   and Bob in the USA. The value is stored by Alice in EUR, and when Bob does
   [get b], he gets the value in USD. Similarly, if he does [set b 50] to put
   50USD on the account, then Alice's value will automatically have the amount
   in EUR.

    What is interesting is that the transformation functions can also have {e
   side-effects}. For instance, send an email each time Bob or Alice modifies
   the amount.

    A more prosaic example would be a slider which shares its value as an
   integer between 0 and 100, and another widget which needs to read/save this
   value as a float between 0 and 1, and each one of them gets notified when the
   other changes the value.

{R {{:graph-b_tvar.html}Dependency graph}} *)
module Tvar : sig
  type ('a, 'b) t
  (** a transform variable of type [('a,'b)] is a variable of type ['b] attached to
     a variable of type ['a Var.t] by a bi-directional transformation. *)
      
end (* of Tvar *)

(* ---------------------------------------------------------------------------- *)

(** Animated variables

    An Avar.t is a special case of dynamic variables [Dynvar], where we know
     that the variable will be used (and thus, updated) at every iteration of
     the main loop. 

{R {{:graph-b_avar.html}Dependency graph}}
*)
module Avar : sig
  type 'a t

  type direction =
    | No
    | Left
    | Right
    | Top
    | Bottom
    | TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Random
  type callback = unit -> unit

  (** {2 Avar information} *)
    
  val progress : 'a t -> float
  (** [progress v] is a float in [0,1] giving the percentage of the animation
     when the last v.value was computed. In case of infinite animation, this is
     just the elapsed Time (in ms). *)
  
  (** {2 Avar creation} *)

  val create : ?duration:Time.t ->
    ?init:callback ->
    ?ending:callback ->
    ?finished:bool -> ?update:('a t -> float -> 'a) -> 'a -> 'a t
  (** Generic Avar creation. If [finished = true], the var never gets updated, {e
     ie} behaves like a normal Var. Otherwise, the [update] parameter is
     compulsory. [update] is a function [v -> t -> 'a] which gives the new value
     of the variable given the old value [v], where [t] is the current timing of
     the animation as described in {!progress}. *)
      
  val fromto : ?duration:int -> ?ending:callback -> int -> int -> int t
  (** [fromto x1 x2] creates a integer Avar.t with initial value [x1] and, as
      time elapses, moves continuously to [x2], with a final slowdown. *)
end (* of Avar *)

(* ---------------------------------------------------------------------------- *)

(** Unions of ranges of integers

{R {{:graph-b_selection.html}Dependency graph}}
 *)
module Selection : sig
  type t
    
end (* of Selection *)

(* ---------------------------------------------------------------------------- *)

(** {2 Widgets}

    Widgets are building blocks of the GUI. They also receive all events (mouse
   focus, etc.) and contain the {e intelligence} of your GUI, through {e
   connections} (or callbacks, see {!Widget.connection}). However, in order to
   be displayed, they need to be packed into {e layouts} ({!Layout.t}). *)

(** Image widget

{R {{:graph-b_image.html}Dependency graph}}
 *)
module Image : sig
  type t

  val create : ?width:int -> ?height:int -> ?noscale:bool -> ?bg:Draw.color -> string -> t
  (** [create "image.jpg"] will load the image ["image.jpg"] (using the path
     [Theme.get_path "image.jpg"]). The actual load occurs only once, on the
     first time the image widget is effectively displayed. The image is then
     stored in a texture. All
     {{:https://www.libsdl.org/projects/SDL_image/}Sdl_image} image formats are
      supported. *)

  val create_from_svg : ?width:int -> ?height:int -> ?bg:Draw.color -> string -> t
  (** Load an svg image. This requires the [rsvg] program. *)
    
end (* of Image *)

(* ---------------------------------------------------------------------------- *)

(** Line and box styles

{R {{:graph-b_style.html}Dependency graph}}
 *)
module Style : sig
  type line_style = (* not implemented *)
    | Solid
    | Dotted of (int * int)
  type line
  type border
  type gradient
  type background =
  | Image of Image.t (* pattern image *)
  | Solid of Draw.color
  | Gradient of gradient

  val color_bg : Draw.color -> background
  val gradient : ?angle:float -> Draw.color list -> background
  val hgradient : Draw.color list -> background
  val vgradient : Draw.color list -> background
  val line : ?color:Draw.color -> ?width:int -> ?style:line_style -> unit -> line
  val border : ?radius:int -> line -> border
end (* of Style *)

(* ---------------------------------------------------------------------------- *)

(** One-line text widget

{R {{:graph-b_label.html}Dependency graph}}
 *)
module Label : sig
  type t
  type font

  val create : ?size:int -> ?font:font -> ?style:Tsdl_ttf.Ttf.Style.t ->
    ?fg:Draw.color -> string -> t
  (** Create a new Label.t *)

  val icon : ?size:int -> ?fg:Draw.color -> string -> t
  (** Create a Label.t using the name of a Fontawesome symbol *)
    
  val set : t -> string -> unit
  (** Modify the text of the label *)

  val set_fg_color : t -> Draw.color -> unit

  val size : t -> int * int
  (** Logical size (w,h). Warning, a +/- 1 error can be observed due
     to rounding. *)
                 
end (* of Label *)

(* ---------------------------------------------------------------------------- *)

(** Button widget with text or icon 

{R {{:graph-b_button.html}Dependency graph}}
*)
module Button : sig
  type t
  type kind =
    | Trigger (* one action when pressed. TODO, better to avoid name clash with
                 Trigger module*)
    | Switch (* two states *)

  val state : t -> bool
  val reset : t -> unit
  val is_pressed : t -> bool
end (* of Button *)

(* ---------------------------------------------------------------------------- *)

(** Slider widget

{R {{:graph-b_slider.html}Dependency graph}}
 *)
module Slider : sig
  type t
  type  kind =
    | Horizontal (* horizontal bar with a small slider; NO background *)
    | HBar (* horizontal bar filled up to the value *)
    | Vertical
    | Circular 

  val size : t -> int * int
             
  val value : t -> int
  (** Get current value. *)

  val set : t -> int -> unit
  (** Set a new value. *)
    
end (* of Slider *)

(* ---------------------------------------------------------------------------- *)

(** Checkbox widget

{R {{:graph-b_check.html}Dependency graph}}
 *)
module Check : sig
  type t
  type style

  val create :  ?state:bool -> ?style:style -> unit -> t
end (* of Check *)

(* ---------------------------------------------------------------------------- *)

(** Multi-line text display widget

{R {{:graph-b_text_display.html}Dependency graph}}
 *)
module Text_display : sig
  type t
  type words

  (** {2 Preparing the text} *)
    
  val example : words
  val raw : string -> words
  val bold : words -> words
  val italic : words -> words
  val normal : words -> words
  val underline : words -> words
  val strikethrough : words -> words
  val page : words list -> words list
  val para : string -> words
  val paragraphs_of_string : string -> words list
    
  (** {2 Creating the widgets} *)

  (** {2 Modifying the widgets} *)
    
  val update_verbatim : t -> string -> unit
    
end (* Text_display *)

(* ---------------------------------------------------------------------------- *)

(** One-line text-input widget

{R {{:graph-b_text_input.html}Dependency graph}}
 *)
module Text_input : sig
  type t
  type filter = string -> bool

  val uint_filter : filter
  val text : t -> string
    
end (* of Text_input *)

(* ---------------------------------------------------------------------------- *)

(** Box widget 

{R {{:graph-b_box.html}Dependency graph}}
*)
module Box : sig
  type t

  val create : ?width:int -> ?height:int ->
    ?background:Style.background -> ?border:Style.border -> unit -> t
    
end (* of Box *)

(* ---------------------------------------------------------------------------- *)

(** Creating and using widgets 

{R {{:graph-b_widget.html}Dependency graph}}
*)
module Widget : sig
  type t
    
  (** {2:connections Connections}

      A connection has a source widget and a target widget. When the source
      widget receives a specified event, the connection is activated, executing a
      specified function. *)
  type connection
  type action = t -> t -> Tsdl.Sdl.event -> unit

  (** what to do when the same action (= same connection id) is already running ? *)
  type action_priority = 
    | Forget (** discard the new action *)
    | Join (** execute the new after the first one has completed *)
    | Replace (** kill the first action (if possible) and execute the second one *)
    | Main (** run in the main program. So this is blocking for all subsequent actions *)  

  val connect : t -> t -> action ->
    ?priority:action_priority ->
    ?update_target:bool -> ?join:connection -> Trigger.t list -> connection
  (** [connect source target action triggers] creates a connection from the
     [source] widget to the [target] widget, but does not register it ({e this
     may change in the future...}). Once it is registered (either by
     {!Main.make} or {!add_connection}), and has {e focus}, then when an event
     [ev] matches one of the [triggers] list, the [action] is executed with
     arguments [source target ev]. *)

  val connect_main : t -> t -> action ->
    ?update_target:bool -> ?join:connection -> Trigger.t list -> connection
  (** Alias to [connect ~priority:Main]. Should be used for very fast actions
     that can be run in the main thread. *)
    
  val add_connection : t -> connection -> unit
  (** Registers the connection with the widget. This should systematically be
     done after each connection that is created {e after}
     {!Main.make}. {e [add_connection] is separated from {!connect} because it is
     not pure: it mutates the widget. This might change in future versions.} *)
    
  val update : t -> unit
  (** Ask for refresh at next frame. Use this in general in the action of a
     connection in case the action modifies the visual state of the widget,
     which then needs to be re-drawn. *)

  (** {3 Predefined connections} *)

  val on_release : release:(t -> unit) -> t -> unit
  (** [on_release ~release:f w] registers on the widget [w] the action [f],
     which will be executed when the mouse button is released on this widget. 
      {e Uses [priority=Main]} *)

  val on_click : click:(t -> unit) -> t -> unit
  (** {e Uses [priority=Main]} *)

  val mouse_over : ?enter:(t -> unit) -> ?leave:(t -> unit) -> t -> unit

  
  (** {2:widget_create Creation of Widgets} *)
    
  (** {3 Simple boxes (rectangles)} *)
    
  val box :
    ?w:int -> ?h:int ->
    ?background:Style.background -> ?border:Style.border -> unit -> t

  (** {3 Check boxes}
      The standard on/off check boxes. *)
    
  val check_box : ?state:bool -> ?style:Check.style -> unit -> t
  val set_check_state : t -> bool -> unit

  (** {3 Text display}
      Use this for multi-line text. *)

  val text_display :  ?w:int -> ?h:int -> string -> t
  val rich_text : ?size:int -> ?w:int -> ?h:int -> Text_display.words list -> t
  val verbatim : string -> t
    
  (** {3 Labels or icons} 
      One-line text. *)

  val label : ?size:int -> ?fg:Draw.color -> ?font:Label.font -> string -> t

  val icon : ?size:int -> ?fg:Draw.color -> string -> t
  (** fontawesome icon *)
  
  (** {3 Empty}
      Does not display anything but still gets focus and reacts to events. *)

  val empty : w:int -> h:int -> unit -> t

  (** {2 Generic functions on widgets} *)
    
  val get_state : t -> bool
  (** query a boolean state. Works for Button.t and Check.t *)

  val get_text : t -> string
  (** Return the text of the widget. Works for Button.t, TextDisplay.t, Label.t,
     and TextInput.t *)
  
  val set_text : t -> string -> unit
  (** Change the text of a widget. Works for Button.t, TextDisplay.t, Label.t,
     and TextInput.t *)

  (** {3 Image} *)

  val image : ?w:int -> ?h:int -> ?bg:Draw.color ->
    ?noscale:bool -> string -> t
  (** Load image file. *)
    
  val image_from_svg : ?w:int -> ?h:int -> ?bg:Draw.color -> string -> t
  (** Requires [rsvg]. *)
    
  (** {3 Text input} *)
    
  val text_input : ?text:string -> ?prompt:string ->
    ?size:int -> ?filter:Text_input.filter -> ?max_size:int -> unit -> t

  (** {3 Buttons} *)

  val button : ?kind:Button.kind -> ?label:Label.t ->
    ?label_on:Label.t -> ?label_off:Label.t ->
    ?fg:Draw.color ->
    ?bg_on:Style.background -> ?bg_off:Style.background ->
    ?bg_over:Style.background ->
    ?state:bool ->
    ?border_radius:int -> ?border_color:Draw.color -> string -> t
    
  (** {3 Sliders} *)

  val slider : ?priority:action_priority -> ?step:int -> ?value:int ->
    ?kind:Slider.kind ->
    ?var:(int Avar.t, int) Tvar.t ->
    ?length:int -> ?thickness:int -> ?tick_size:int -> ?lock:bool -> int -> t

  val slider_with_action : ?priority:action_priority ->
    ?step:int -> ?kind:Slider.kind -> value:int -> ?length:int ->
    ?thickness:int -> ?tick_size:int -> action:(int -> unit) -> int -> t
  (** Create a slider that executes an action each time the local value of the
     slider is modified by the user. *)
  
  (** {2 Creation of combined widgets} *)

  val check_box_with_label : string -> t * t
  (** [let b,l = check_box_with_label text] creates a check box [b], a label
     [l], and connect them so that clicking on the text will also act on the
     check box. *)
  
  (** Conversions from the generic Widget type to the specialized inner type *)

  val get_box : t -> Box.t
  val get_check : t -> Check.t
  val get_label : t -> Label.t
  val get_button : t -> Button.t
  val get_slider : t -> Slider.t
  val get_text_display : t -> Text_display.t
  val get_text_input : t -> Text_input.t
end (* of Widget *)

(* ---------------------------------------------------------------------------- *)

(** Updating widgets

{R {{:graph-b_update.html}Dependency graph}}
*)
module Update : sig

  val push : Widget.t -> unit
  (** Register a widget for being updated (at next frame) by the main loop. *)
    
end (* of Update *)

(* ---------------------------------------------------------------------------- *)


(** {2 Layouts}

    Layouts are rectangular graphical placeholders, in which you should pack all
   your widgets in order to display your GUI. Sophisticated gadgets are usually
   obtained by combining several layouts together.  *)


(** The main, all-purpose graphics container

 A layout is a "box" (a rectangle) whose purpose is to place onscreen the
   various elements composing the GUI. It can contain a single widget, or a list
   of sub-layouts. We often use the housing metaphor: a layout is a house that
   contains either a single resident, or several rooms. Each room can be seen as
   a sub-house, and can contain a resident or sub-rooms. Houses and rooms have
   the type {!t}, while a resident has the type {!Widget.t}.

     Technically, the usual metaphor in computer science is a {e Tree}. A layout
   is a tree, each vertex (or node) has any number of branches (or children). A
   leaf (terminal node: without any child) is either empty or contains a
   widget. However, the tree is upside-down (as often): we think of the trunk
   (or {e top-layout}) to be a the top, and the leaves at the bottom. 

{R {{:graph-b_layout.html}Dependency graph}}
*)
module Layout : sig
  type t

  exception Fatal_error of (t * string)
    
  type room_content =
    | Rooms of t list
    | Resident of Widget.t
                    
  (** Not implemented. *)
  type adjust   =
  | Fit
  | Width
  | Height
  | Nothing

  (** {2 Backgrounds} *)

  (** Warning, there is also Style.background... Maybe this will change in the
      future. *)
  type background

  val color_bg : Draw.color -> background
  val box_bg : Box.t -> background
    
  val unload_background : t -> unit
  (** Free the texture associated with the background (if any). This can be used
     to force recreating it. *)
  
  (** {2 Creation of layouts} 

      All layouts have a [name] property, which is used only for debugging. *)

  val empty : ?name:string -> ?background:background -> w:int -> h:int -> unit -> t
  (** An empty layout can reserve some space without stealing focus. *)
     
  (** {3 Create layouts from widgets} *)
    
  val resident :
    ?name:string -> ?x:int -> ?y:int -> ?w:int -> ?h:int ->
    ?background:background ->
    ?draggable:bool ->
    ?canvas:Draw.canvas ->
    ?layer:Draw.layer -> ?keyboard_focus:bool -> Widget.t -> t
  val flat_of_w :
    ?name:string -> ?sep:int -> ?h:int ->
    ?align:Draw.align ->
    ?background:background ->
    ?widget_bg:background -> ?canvas:Draw.canvas -> Widget.t list -> t
  val tower_of_w :
    ?name:string -> ?sep:int ->
    ?align:Draw.align ->
    ?background:background ->
    ?widget_bg:background -> ?canvas:Draw.canvas -> Widget.t list -> t

  (** {3 Create layouts from other layouts} *)
    
  val flat :
    ?name:string -> ?sep:int ->
    ?adjust:adjust -> ?hmargin:int -> ?vmargin:int -> ?margins:int ->
    ?align:Draw.align ->
    ?background:background -> ?canvas:Draw.canvas -> t list -> t
  val tower :
    ?name:string -> ?sep:int ->
    ?margins:int -> ?hmargin:int -> ?vmargin:int ->
    ?align:Draw.align ->
    ?adjust:adjust ->
    ?background:background -> ?canvas:Draw.canvas -> t list -> t
  val superpose : ?w:int -> ?h:int -> ?name:string ->
    ?background:background -> ?canvas:Draw.canvas -> t list -> t
  (** Create a new layout by superposing a list of layouts without changing
      their (x,y) position. *)

  (** {2 Some useful layout combinations} *)
    
  val make_clip : ?w:int ->
    ?scrollbar:bool ->
    ?scrollbar_inside:bool -> ?scrollbar_width:int -> h:int -> t -> t
  (** Clip a layout inside a smaller container and make it scrollable, and
      optionally add a scrollbar widget. *)
  
  (** {2 Get layout attributes} *)

  val xpos : t -> int
  (** get current absolute x position of the layout (relative to the top-left
      corner of the window) *)

  val ypos : t -> int
  (** see {!xpos} *)

  val width : t -> int
  val height : t -> int
  val get_size : t -> int * int
  (** [get_size l] is equivalent to [(width l, height l)] *)

  val get_physical_size : t -> int * int
  (** multiplies [get_size] by the Theme scaling factor. This gives in principle
     the correct size in physical pixels, up to an error of +/- 1pixel, due to
     rounding error. *)

  val getx : t -> int
  (** Compute the relative x position of the room with respect to its house,
     using animations if any. Because of this, this function should not be
      called by the animation itself! Use {!get_oldx} instead.  *)

  val get_oldx : t -> int
  (** Return the last computed value for the relative x position of the
     layout. *)

  val gety : t -> int
  val get_oldy : t -> int
    
  val widget : t -> Widget.t
  (** Return the resident widget, or @raise Not_found if the layout is not a {e
     leaf}. *)

  val top_house : t -> t
  (** Return the top of the layout tree (the "house" that contains the given
     layout and that is not contained in another layout). It is the only layout
     that is directly attached to a "physical" (SDL) window. *)

  val get_content : t -> room_content
  
  (** {2 Modify existing layouts}

      These functions will not work if there is an animation running acting of the
     variable we want to set. *)

  val set_width : ?update_bg:bool -> t -> int -> unit
  val set_height : t -> int -> unit
  val setx : t -> int -> unit
  val sety : t -> int -> unit
  val set_show : t -> bool -> unit

  val fit_content : ?sep:int -> t -> unit
  (** Adapt the size of the layout (and their houses) to the disposition of the
     contained rooms. *)

  val set_rooms : t -> ?sync:bool -> t list -> unit
  (** Modify the layout content by replacing the former content by a new list of
     rooms. Use [sync=true] (the default) as much as possible in order to avoid
     multi-threading problems. Then the changes will be applied by the main
      thread at next frame (see {!Sync}). *)

  val unload_textures : t -> unit
  (** Use this to free the textures stored by the layout (and its children) for
     reducing memory. The layout can still be used without any impact, the
     textures will be recreated on the fly.  *)
    
  val lock : t -> unit
  val unlock : t -> unit
  (** Since layouts can be modified by different threads, it might be useful to
     lock it with a mutex. This does *not* always prevent from modifying it, but
     another [lock] statement will wait for the previous lock to be removed by
     {!unlock}. *)
    
  
  (** {2 Animations}

      Position, size, alpha channel, and rotation of Layouts use [Avar]
     variables and hence can be easily animated. Most predefined animations have
      a default duration of 300ms. *)

  (** {3 Generic animations}

      These functions assign an animated variable if type {!Avar.t} to one
     of the properties of the layout (position, width, etc.)  *)
    
  val animate_x : t -> int Avar.t -> unit
  (** Assign an Avar to the layout x position. *)

  val animate_y : t -> int Avar.t -> unit
  val stop_pos : t -> unit
  (** Stop animations of the variables x and y. *)

  val animate_w : t -> int Avar.t -> unit
  val animate_h : t -> int Avar.t -> unit
  val animate_alpha : t -> float Avar.t -> unit
  val animate_angle : t -> float Avar.t -> unit
    
  (** {3 Predefined animations} *)
    
  val hide : ?duration:int -> ?towards:Avar.direction -> t -> unit
  (** See {!show}. *)

  val show : ?duration:int -> ?from:Avar.direction -> t -> unit
  (** Does nothing if the layout is already fully displayed. Only the
     [Avar.Top] and [Avar.Bottom] directions are currently implemented. For
     these directions, [hide] and [show] do {e not} modify the position
     variables (x,y) of the layout, they use a special variable called
     [voffset]. *)

  val fade_in : ?duration:int -> ?from_alpha:float -> ?to_alpha:float ->
    t -> unit
  (** Animate the alpha channel of the layout. Can be combined with animations
     involving the other animated variables. Does {e not} modify the [show]
     status of the layout. By default, [from_alpha=0.] (transparent) and
      [to_alpha=1.]  (opaque).  *)

  val fade_out : ?duration:int ->
    ?from_alpha:float -> ?to_alpha:float -> ?hide:bool -> t -> unit
  (** See {!fade_in}. WARNING: fading out to alpha=0 results in a completely
     transparent layout, but the layout is {e still there} (it's not
     "hidden"). Which means it can still get mouse focus. If you want to hide
     it, then use [hide=true]. By default, [hide=false], [from_alpha] is the
     current alpha of the layout, and [to_alpha=0.] *)

  val rotate : ?duration:int -> ?from_angle:float -> angle:float -> t -> unit
  (** Rotate all widgets inside the layout around their respective centers. For
      a global rotation, use a {!Snapshot}. *)
    
  val slide_in : ?from:Avar.direction -> dst:t -> t -> unit
  val slide_to : ?duration:int -> t -> int * int -> unit
  (** [slide_to room (x0,y0)] will translate the [room] to the position
     [(x0,y0)]. *)

  val follow_mouse : ?dx:int -> ?dy:int ->
    ?modifierx:(int -> int) -> ?modifiery:(int -> int) -> t -> unit
  val oscillate : ?duration:int -> ?frequency:float -> int -> t -> unit
  val zoom : ?duration:int -> from_factor:float -> to_factor:float -> t -> unit

  val reflat : ?align:Draw.align ->
    ?hmargin:int -> ?vmargin:int -> ?margins:int -> ?duration:int -> t -> unit
  (** Adjust an existing layout to arrange its rooms in a "flat" fashion, as if
     they were created by {!Layout.flat}. Will be animated if [duration <> 0]. *)

  val retower : ?align:Draw.align ->
    ?hmargin:int -> ?vmargin:int -> ?margins:int -> ?duration:int -> t -> unit
    
  (** {2 Windows}

      A very special use of layout is to represent the 'window' on which
     everything is drawn. Thus, this specific to the 'main house' (or {e
     top-layout}), {e i.e.} a layout that is not a sublayout of another
     layout. *)

  val window : t -> Tsdl.Sdl.window
                         
  val set_window_pos : t -> int * int -> unit
  (** It should be set {b after} {!Main.make} and {b before}
     {!Main.run}. Otherwise it has possibly no effect, or perhaps causes some
      glitches.  *)

  (** {2 Misc} *)

  val set_cursor : t option -> unit
  (** Sets the cursor to the default value for this layout. *)
    
end (* of Layout *)

(* ---------------------------------------------------------------------------- *)

(** Adjust various spacings and sizes of layouts

These functions {e do not take effect immediately!} They will be executed, in
   the order of their invocation, at the next graphics frame (or at startup if
   they are invoked before the start of the mainloop).  

{R {{:graph-b_space.html}Dependency graph}}
*)
module Space : sig

  
  val hfill : ?margin:int -> unit -> Layout.t
  (** When used in a {!Layout.flat} structure, this special empty layout will
     automatically expand in order to fill the available width in the parent
     house. *)

  val vfill : ?margin:int -> unit -> Layout.t
  (** When used in a {!Layout.tower} structure, this special empty layout will
     automatically expand in order to fill the available height in the parent
     house. *)

  val full_width : ?margin:int -> Layout.t -> unit
  (** This will set the width of the room (layout) in order to occupy the whole
     width of its house. *)

  val make_hfill : ?margin:int -> Layout.t -> unit
  (** Like {!hfill}, but applies to the specified layout instead of creating an
      empty one. *)

  val make_vfill : ?margin:int -> Layout.t -> unit
    
  val vcenter : Layout.t -> unit
  (** Will vertically center the layout in its house. *)
end (* of Space *)

(* ---------------------------------------------------------------------------- *)

(** Convert Bogue objects to strings for debugging 

{R {{:graph-b_print.html}Dependency graph}}
*)
module Print : sig

  val layout_down : ?indent:string -> Layout.t -> string
  (** Print a layout with all its rooms and subrooms (children). *)

  val layout_up : ?indent:string -> Layout.t -> string
  (** Print the layout node and all the rooms (houses, or parents) in which it
      is contained. *)

  val layout_error : Layout.t -> string -> unit
  (** Print a message to stderr and dump the top_house structure to a temporary
     file. *)
    
end (* of Print *)

(* ---------------------------------------------------------------------------- *)

(** Create an image from a Layout 

{R {{:graph-b_snapshot.html}Dependency graph}}
*)
module Snapshot : sig

  val create : ?border:Style.border -> Layout.t -> Widget.t
  (** Should be called from the main thread only. There are some issues with
     transparency. @return a Box widget. *)
                                                                   
end (* of Snapshot *)

(* ---------------------------------------------------------------------------- *)

(** Handle large lists by not displaying all elements at once

Very quickly, displaying a list of layouts (for instance, listing files in a
   directory) can run the computer out of memory if it tries to keep in memory
   the textures of {b all} entries of the list. In these cases you need to use a
   [Long_list]. 

{R {{:graph-b_long_list.html}Dependency graph}}
*)
module Long_list : sig
  type t

  val create : w:int -> h:int -> length:int ->
    ?first:int ->
    generate:(int -> Layout.t) ->
    ?height_fn:(int -> int option) ->
    ?cleanup:(Layout.t -> unit) ->
    ?max_memory:int ->
    ?linear:bool -> ?scrollbar_width:int -> unit -> Layout.t
  (** Create a long list through the function [generate] which maps any index
     {em i} to the {e ieth} element (layout) of the list. If specified (which is
     not a good idea), the [max_memory] should be at least twice the area (in
     physical pixels) of the visible part of the list. If the number of elements
     is large (typically 100000 or more, this depends on your CPU), its is
     highly advisable to provide a [height_fn], which to an index {e i} gives
     the height (in logical pixels) of the {e ieth} entry. If some heights are
     not known in advance, it's ok to return [None]. For instance, if all
     entries have the same height, say 30 pixels, one can define

      {[ let height_fn _ = Some 30 ]} *)
                                                      
end (* of Long_list *)

(* ---------------------------------------------------------------------------- *)

(** Switch between layouts using Tabs 

{R {{:graph-b_tabs.html}Dependency graph}}
*)
module Tabs : sig

  val create : 
    ?slide:Avar.direction ->
    ?adjust:Layout.adjust -> ?expand:bool ->
    ?canvas:Draw.canvas ->
    ?name:string -> (string * Layout.t) list -> Layout.t
end (* of Tabs *)

(* ---------------------------------------------------------------------------- *)

(** Put layouts on top of others 

{R {{:graph-b_popup.html}Dependency graph}} *)
module Popup : sig

  val add_screen : ?color:Draw.color -> Layout.t -> Layout.t
  (** Add a screen on top of the layout. This can be useful to make the whole
     layout clickable as a whole. @return the screen. *)
  
  (** Generic modal type popup *)
  val attach : ?bg:Draw.color ->
    ?show:bool -> Layout.t -> Layout.t -> Layout.t
  (** [attach house layout] adds two layers on top of the house: one for the
     screen to hide the house, one for the layout on top of the screen. @return
      the screen. *)

  val info : ?w:int -> ?h:int -> ?button:string -> string -> Layout.t -> unit
  (** Add to the layout a modal popup with a text and a close button. By
     default, [button="Close"]. *)

  val yesno : ?w:int -> ?h:int ->
    ?yes:string -> ?no:string ->
    yes_action:(unit -> unit) ->
    no_action:(unit -> unit) -> string -> Layout.t -> unit
  (** Add to the layout a modal popup with two yes/no buttons. By default,
      [yes="Yes"] and [no="No"]. *)

  val two_buttons : ?w:int -> ?h:int -> label1:string -> label2:string ->
    action1:(unit -> unit) -> action2:(unit -> unit) ->
    Layout.t -> Layout.t -> unit

  type position =
  | LeftOf
  | RightOf
  | Above
  | Below
  | Mouse

  val tooltip : ?background:Layout.background ->
    ?position:position ->
    string -> target:Layout.t -> Widget.t -> Layout.t -> unit
  (** [tooltip text ~target widget layout] adds a tooltip which will appear on
     [layout], next to [target] (which should be a sublayout of [layout]), when
     the [widget] gets mouse focus and mouse is idle for some time on it. A
     tooltip it not a modal popup, it does not prevent from interacting with the
     rest of the layout. *)
    
end (* of Popup *)

(* ---------------------------------------------------------------------------- *)

(** Various types of menus 

{R {{:graph-b_menu.html}Dependency graph}}
*)
module Menu : sig

  type t
    
  type simple_entry = {
    text : string;
    action : unit -> unit;
  }
  
  type mutable_text = {
    mutable text : string;
    action : string -> unit; (** The text can be modified by the action *)
  }

  type check_entry = {
    mutable state : bool; (** A check box before the label, and the text is modifiable *)
    mutable text : string;
    action : string -> bool -> unit
  }

  type layout_entry = {
    layout : Layout.t;
    selected : bool Var.t; (* true if the mouse is over this entry *)
    action : Layout.t -> unit;
    (* the action will be executed when the mouse is clicked AND released on the
       entry (at {!Trigger.mouse_button_up}) *)
    submenu : t option
    (* The layouts of the submenu belong to the layout of this entry, hence the
       position of the submenu should be calculated relative to the entry. *)
  }
    
  type label =
    | Label of simple_entry
    | Dynamic of mutable_text
    | Check of check_entry
    | Layout of layout_entry;;

  type entry = {
    label : label;
    submenu : (entry list) option;
  }

  val create_menu : ?depth:int -> layout_entry array -> bool -> t
  (** The [depth] indicates the level of submenu. By default [depth=0]. The
     [bool] parameter indicate whether the menu should be initially shown. *)

  val create : ?hide:bool -> ?name:string ->
    ?background:Layout.background ->
    ?select_bg:Layout.background -> dst:Layout.t -> t -> Layout.t
  (** By default, [hide=false]. The [dst] layout will contain the
     submenus. @return the layout of the main menu. This is generic menu
     construction function, it does {b not} compute the positions of the
     entries. See [example41]. *)
                                                              
  val bar : ?background:Layout.background ->
    ?name:string -> Layout.t -> entry list -> Layout.t
  (** A menu bar, with drop-down submenus. [bar dst entries] creates a layout
     which contains the menu bar on top of the [dst] layout. The [dst] layout
     should be big enough to contain the submenus. Any item flowing out of [dst]
     will not get focus. The system will automatically try to shift the submenus
     if they are too wide, or add a scrollbar if they are too tall. *)
end (* of Menu *)

(* ---------------------------------------------------------------------------- *)

(** Drop-down select list

It's the usual select box which opens a drop-down list when clicked on, similar
   to the [<select>] html tag. 

{R {{:graph-b_select.html}Dependency graph}}
*)
module Select : sig

  type t
  (** Under the hood, a [Select.t] is a special type of menu with a single entry
      having a submenu. *)

  val create : ?dst:Layout.t ->
    ?name:string ->
    ?action:(int -> unit) ->
    ?fg:Draw.color -> ?hmargin:int -> string array -> int -> t
  (** For instance [create [| "A"; "B"; "C" |] 1] will create a select box with
     default choice ["B"]. The [action] (if specified) takes as argument the
     index of the selected item. *)

  val layout : t -> Layout.t
  (** The layout to display the select list. *)

  val selected : t -> int
  (** The index (starting from 0) of the selected item. *)

  val set_label : t -> string -> unit
  (** Modify the label. *)
    
  val set_action : t -> (int -> unit) -> unit
  (** Modify the action. *)

end (* of Select *)

(* ---------------------------------------------------------------------------- *)

(** Check list with a single choice

    Each item of the list is displayed with a 'radio button' in front of it, and
   at most one item can be selected, similarly to [<input type="radio"...>] in
   html. Radiobuttons are implemented with {!Check.t}. 

{R {{:graph-b_radiolist.html}Dependency graph}}
*)
module Radiolist : sig
  type t

  val vertical : ?name:string -> ?click_on_label:bool -> ?selected:int -> string array -> t
  (** A radiolist with the usual vertical layout of items. The option [click_on_label] is true be default: one can click on the label to select it. *)

  val layout : t -> Layout.t
  (** The layout to display the radiolist. *)

  val get_index : t -> int option
  val set_index : t -> int -> unit
  (** Set the selected entry to the specified index and directly activate the
     button's connections with the {!Trigger.var_changed} event. *)

  val active_widgets : t -> Widget.t list
  (** @return the list of widgets that are active for selecting entries ({e
     i.e.} either radiobuttons or radiobuttons and labels, depending on
     [click_on_label]. *)
end (* of Radiolist *)

(* ---------------------------------------------------------------------------- *)

(** Tables with sortable columns and selectable rows 

{R {{:graph-b_table.html}Dependency graph}}
*)
module Table : sig
  type column =
    { title : string;
      length : int;
      rows : int -> Layout.t;
      compare : (int -> int -> int) option;
      (* use "compare i1 i2" in order to compare entries i1 and i2 *)
      width : int option;
    }
  type t

  val create : ?w:int -> h:int -> ?row_height:int ->
    ?name:string ->
    column list -> Layout.t * (Selection.t, Selection.t) Tvar.t
  (** @return a layout and a Tvar. The Tvar can be used to see which rows were
     selected by the user, and also to modify the selection if needed. *)
end (* of Table *)

(* ---------------------------------------------------------------------------- *)

(** {2 The Bogue mainloop}

Because a GUI continuously waits for user interaction, everything has to run
   inside a loop.  *)

(** Control the workflow of the GUI mainloop 

{R {{:graph-b_main.html}Dependency graph}}
*)
module Main : sig
  type board
  (** The board is the whole universe of your GUI. It contains everything. *)
  
  exception Exit
  (** Raising the [Exit] exception will tell the GUI loop to terminate. *)
    
  val make : Widget.connection list -> Layout.t list -> board
  val run :
    ?before_display:(unit -> unit) ->
    ?after_display:(unit -> unit) -> board -> unit

  (** {2 Using Bogue together with another graphics loop} 

      See the [embed] example. *)
    
  val make_sdl_windows : ?windows:Tsdl.Sdl.window list -> board -> unit
  (** This is only useful if you have your own graphics loop, and do {e not} use
     {!run}. This function creates an SDL window for each top layout in the
     board. One can use predefined windows with the optional argument
     [windows]. They will be used by the layouts in the order they appear in the
     list. If there are fewer windows than layouts, new windows are created. If
      there are more, the excess is disregarded. *)

  val refresh_custom_windows : board -> unit
  (** Ask the GUI to refresh (ie. repaint) the custom windows (those that were
     not created by Bogue itself). *)
  
  val one_step : ?before_display:(unit -> unit) ->
    bool -> (unit -> unit) * (unit -> unit) -> ?clear:bool -> board -> bool
  (** This is only useful if you have your own graphics loop, and do {e not} use
     {!run}. Calling [one_step ~before_display anim (start_fps, fps) ~clear
     board] is what is executed at each step of the Bogue mainloop. If
     [anim=true] this step is {e non blocking}; this is what you want if either
     Bogue or your loop has an animation running. If [anim=false] then the
     function will wait until an event is received. @return [true] if the GUI
     currently handles an animation. In this case [fps()] was executed by
     [one_step]. If not, you should handle the frame rate yourself. *)
    
end (* of Main *)

(* ---------------------------------------------------------------------------- *)

(** Alias for [Main] *)
module Bogue = Main
  
(* ---------------------------------------------------------------------------- *)

(** {2:example Example}

    Here is a minimal example with a label and a check box.

{[
open Bogue
module W = Widget
module L = Layout

let main () =

  let b = W.check_box () in
  let l = W.label "Hello world" in
  let layout = L.flat_of_w [b;l] in

  let board = Bogue.make [] [layout] in
  Bogue.run board;;

let () = main ();
  Draw.quit ()
]}

This can be compiled to bytecode with

{v
ocamlfind ocamlc -package bogue -linkpkg -o minimal -thread minimal.ml
v}

and to native code with

{v
ocamlfind ocamlopt -package bogue -linkpkg -o minimal -thread minimal.ml
v}

  *)
