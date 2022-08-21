
if known context_gnuplot : endinput; fi;

boolean context_gnuplot ; context_gnuplot := true;

	string gnuplotversion;

	def gp_setup_before =
	enddef;

	def gp_setup_after =
	enddef;

	newinternal gp_align_center, gp_align_left, gp_align_right;
	gp_align_center := 0;
	gp_align_left   := 1;
	gp_align_right  := 2;


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% Colors & Dashes
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	boolean gp_use_color;  gp_use_color  := true;
	boolean gp_use_dashed; gp_use_dashed := true;

	% default background color (should we set it somewhere?)
	color gp_color_background; gp_color_background := white;
	% default foreground color (also set in t-gnuplot.tex)
	color gp_color_foreground; gp_color_foreground := black;
	% current color
	color gp_color_current;    gp_color_current := gp_color_foreground;

	% colors corresponding to linetypes
	%
	% LT_AXIS       (-1)
	% LT_BLACK      (-2)
	% LT_NODRAW     (-3)
	% LT_BACKGROUND (-4)
	% LT_UNDEFINED  (-5)

	color gp_color_lt[];
	numeric gp_num_linetype; gp_num_linetype := 9;
	gp_color_lt[-4] = gp_color_background;
	gp_color_lt[-3] = gp_color_background; % TODO: nodraw!!!
	gp_color_lt[-2] = gp_color_foreground;
	% TODO: do we need this to be configurable?
	gp_color_lt[-1] = gp_color_foreground; % coordinate axes
	gp_color_lt[0] = red;
	gp_color_lt[1] = green;
	gp_color_lt[2] = blue;
	gp_color_lt[3] = magenta;
	gp_color_lt[4] = cyan;
	gp_color_lt[5] = yellow;
	gp_color_lt[6] = black;
	gp_color_lt[7] = (1,.3,0); % orange; perhaps it's defined already
	gp_color_lt[8] = .5white;

	% dashes corresponding to linetypes - copied from PostScript terminal
	% perhaps check the other terminals as well!!!

	% scaling factor for dash lengths
	gp_scale_dashlength := 1;
	% TODO: set some sensible default scaling factor (compare with PostScript)
	gp_dashlength := 1;

	% TODO: watch out linecaps and linejoins !!! (possibly rewrite)
	% TODO: compare with PostScript lines and possibly fix,
	% so that they will match
	%
	% TODO: write a macro to make these definitions slightly nicer
	%
	% linecap := butt; ???
	picture gp_dash_lt[];
	gp_dash_lt[-3] := dashpattern(on 0 off 1) scaled (gp_scale_dashlength*gp_dashlength); % TODO: this is wrong anyway; it should generate an XORed line
	gp_dash_lt[-2] := dashpattern();
	% for axes
	gp_dash_lt[-1] := dashpattern(on 2 off 1) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[0]  := dashpattern();
	gp_dash_lt[1]  := dashpattern(on 4 off 2) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[2]  := dashpattern(on 2 off 3) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[3]  := dashpattern(on 1 off 1.5) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[4]  := dashpattern(on 6 off 2 on 1 off 2) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[5]  := dashpattern(on 3 off 3 on 1 off 3) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[6]  := dashpattern(on 2 off 2 on 2 off 6) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[7]  := dashpattern(on 1 off 2 on 6 off 2 on 1 off 2) scaled (gp_scale_dashlength*gp_dashlength);
	gp_dash_lt[8]  := dashpattern(on 2 off 2 on 2 off 2 on 2 off 2 on 2 off 4) scaled (gp_scale_dashlength*gp_dashlength);

	% returns the color for the given linetype modulo gp_num_linetype
	vardef gp_color_linetype(expr linetype) =
		(if linetype < -3:
			gp_color_lt[-3]
%		else:
		elseif linetype >= gp_num_linetype:
			gp_color_lt[(linetype mod gp_num_linetype)]
%			gp_color_lt[1]
		else:
			gp_color_lt[linetype]
		fi)
		% TODO: chech if the number is defined
		% TODO: check if gp_use_color
%		if linetype = -2 :
%			gp_color_lt[-2]
%		elseif linetype = -1 :
%			gp_color_lt[-1]
%		elseif linetype = -1 :
%			gp_color_lt[-3]
%		else :
%			% TODO: check if the number is defined
%			% check, if the number is positive
%			gp_color_lt[ (linetype mod gp_num_linetype) ]
%		fi;
	enddef;

	def gp_dash_linetype(expr linetype) =
		(if linetype < -3:
			gp_dash_lt[-3]
		elseif linetype >= gp_num_linetype:
			gp_dash_lt[(linetype mod gp_num_linetype)]
		else:
			gp_dash_lt[linetype]
		fi)
		% TODO: chech if the number is defined
		% TODO: check if gp_use_color
%		if linetype = -2 :
%			gp_color_lt[-2]
%		elseif linetype = -1 :
%			gp_color_lt[-1]
%		elseif linetype = -1 :
%			gp_color_lt[-3]
%		else :
%			% TODO: check if the number is defined
%			% check, if the number is positive
%			gp_color_lt[ (linetype mod gp_num_linetype) ]
%		fi;
	enddef;

	% gp_set_color(lt(3))
	% gp_set_color(rgb(.5,.5.0))
	% gp_set_color(frac(.3))
	def gp_set_color(text t) =
		begingroup;
		% sets the color to the given (r,g,b) triple
		def rgb(expr r,g,b) =
			gp_color_current := (r,g,b);
		enddef;
		
		% sets the color so that it matches the color of linetype
		def lt(expr linetype) =
			gp_color_current := gp_color_linetype(linetype);
		enddef;

		% sets the color either to gray or according to the current palette
		def frac(expr fraction) =
			% "if palette = gray"
			if gp_palette_color_mode = gp_palette_color_mode_rgb:
				gp_color_current := (
					gp_palette_function(gp_palette_formula_r,fraction),
					gp_palette_function(gp_palette_formula_g,fraction),
					gp_palette_function(gp_palette_formula_b,fraction));
			else:
				% TODO - more advanced paletter
				gp_color_current := fraction*white; % XXX: should this be (1-frac)*white perhaps?
			fi;
		enddef;

		% execute the content - calls one of the definitions from above
		t;
		endgroup;
	enddef;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% Palette
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% for "colorMode==SMPAL_COLOR_MODE_GRADIENT"
	% These variables are used to define interpolated color palettes:
   % there are gradient_num pairs of (frac/gray, color) mappings
%	numeric gp_palette.gradient_num;
%	numeric gp_palette.gradient[].frac;
%	color   gp_palette.gradient[].abc;
	%
	% see palette_color_mode in color.h
	newinternal
		gp_palette_color_mode_none,
		gp_palette_color_mode_gray,
		gp_palette_color_mode_rgb,
		gp_palette_color_mode_functions,
		gp_palette_color_mode_gradient;

	gp_palette_color_mode_none      := 0;
	gp_palette_color_mode_gray      := 1; % grayscale only
	gp_palette_color_mode_rgb       := 2; % one of several fixed transformations
	gp_palette_color_mode_functions := 3; % user-defined transforms
	gp_palette_color_mode_gradient  := 4; % interpolated table: explicitely defined or read from file

	% there is no palette initialized by default
	numeric gp_palette_color_mode;
	gp_palette_color_mode := gp_palette_color_mode_none;

	% mapping formulae for gp_palette_color_mode_rgb
	numeric gp_palette_formula_r; gp_palette_formula_r := 3; % f(x)=x
	numeric gp_palette_formula_g; gp_palette_formula_g := 3;
	numeric gp_palette_formula_b; gp_palette_formula_b := 3;

	% explicitely defined color gradient
	color gp_palette_gradient_colors[];
	numeric gp_palette_gradient_pos[];
	% number of defined colors
	numeric gp_palette_gradient_n;

	% gamma for gray scale palettes only
	numeric gp_palette_gamma;

%	% color model: RGB/HSV/CMY; YIQ, XYZ and others not supported
%	newinternal gp_palette.model.rgb, gp_palette.model.hsv, gp_palette.model.cmy;%, gp_palette.model.yiq, gp_palette.model.xyz;
%	gp_palette.rgb := 0;
%	gp_palette.hsv := 1;
%	gp_palette.cmy := 2;
	%gp_palette.yiq := 3;
	%gp_palette.xyz := 4;
	
	% color model - RGB/HSV/CMY (ie. one of the models above)
%	numeric gp_palette.model;
	
	% for "colorMode == SMPAL_COLOR_MODE_FUNCTIONS"
	% R, G abd B for RGB
	% H, S and V for HSV
	% C, M and Y for CMY
%	color gp_palette.abc;
	
	% gamma (only used for gray scale palettes)
%	numeric gp_palette.gamma; gp_palette.gamma = 1;

	def gp_make_palette(text t) =
		begingroup;
		% let hack: save comma
%		let@=,;
		
		def color_mode(text mode) =
			% let hack
%			let,=@; let@=,;
			save gray, rgb, functions, gradient;
			gray      = gp_palette_color_mode_gray;
			rgb       = gp_palette_color_mode_rgb;
			functions = gp_palette_color_mode_functions;
			gradient  = gp_palette_color_mode_gradient;
		
			gp_palette_color_mode := mode;
		
			% if mode=gray:
			% 	% TODO
			% elseif mode=rgb:
			% 	% TODO
			% elseif mode=functions:
			% 	% TODO
			% elseif mode=gradient:
			% 	% TODO
			% fi;
		
			% let hack: ignore next comma
%			let,=;;
		enddef;
		
		% for gp_palette_color_mode_rgb: numbers of formulae
		def formulae(expr r, g, b) =
			% let hack
%			let,=@; let@=,;
			gp_palette_color_mode := gp_palette_color_mode_rgb;
			gp_palette_formula_r := r;
			gp_palette_formula_g := g;
			gp_palette_formula_b := b;
			% let hack: ignore next comma
%			let,=;;
		enddef;
		
		% TODO: for gradient definitions
		def colors(text tc) =
			gp_palette_gradient_n := 0;
			for i=tc:
				gp_palette_gradient_colors[gp_palette_gradient_n] := i;
				counter := counter+1;
			endfor;
			% let hack
%			let,=@; let@=,;
			% code goes here
			% [TODO]
			%
			% let hack: ignore the following comma
%			let,=;;
		enddef;
		
		% TODO: for gradient definitions
		def positions(text tp) =
			gp_palette_gradient_n := 0;
			for i=tp:
				gp_palette_gradient_pos[gp_palette_gradient_n] := i;
				counter := counter+1;
			endfor;
			% let hack
%			let,=@; let@=,;
			% code goes here
			% [TODO]
			%
			% let hack: ignore the following comma
%			let,=;;
		enddef;
		
		t;
		% let hack: restore comma
%		let,=@;
		endgroup;
	enddef;

	% Functions copied from GetColorValueFromFormula from getcolor.c
	vardef gp_palette_function(expr ff, tt) =
		save f, t;
		f = ff;
		t = tt;
		% the input gray is supposed to be in interval [0,1]
		% for a negative formula, reverse the palette (negate x)
		if f < 0:
			t := -t;
			f := -f;
		fi;
		
		t :=
		if     f =  0: 0
		elseif f =  1: 0.5
		elseif f =  2: 1
		elseif f =  3: t
		elseif f =  4: t*t
		elseif f =  5: t*t*t
		elseif f =  6: t*t*t*t
		elseif f =  7: sqrt(t)
		elseif f =  8: sqrt(sqrt(t))
		elseif f =  9: sind(90t)
		elseif f = 10: cosd(90t)
		elseif f = 11: abs(t-0.5)
		elseif f = 12: (2t-1)*(2t-1)
		elseif f = 13: sind(180t)
		elseif f = 14: abs(cosd(180t))
		elseif f = 15: sind(360t)
		elseif f = 16: cosd(360t)
		elseif f = 17: abs(sind(360t))
		elseif f = 18: abs(cosd(360t))
		elseif f = 19: abs(sind(720t))
		elseif f = 20: abs(cosd(720t))
		elseif f = 21: 3t
		elseif f = 22: 3t-1
		elseif f = 23: 3t-2
		elseif f = 24: abs(3t-1)
		elseif f = 25: abs(3t-2)
		elseif f = 26: 1.5t-0.5
		elseif f = 27: 1.5t-1.0
		elseif f = 28: abs(1.5t-0.5)
		elseif f = 29: abs(1.5t-1.0)
		elseif f = 30: if     t <= 0.25: 0
		               elseif t <= 0.57: t/0.32-0.78125
		               else            : 1
		               fi
		elseif f = 31: if     t <= 0.42: 0
		               elseif t <= 0.92: 2t-0.84
		               else            : 1
		               fi
		elseif f = 32: if     t <= 0.42:  4t
		               elseif t <= 0.92: -2t+1.84
		               else            :   t/0.08-11.5
		               fi
		elseif f = 33: abs(2t-0.5)
		elseif f = 34: 2t
		elseif f = 35: 2t-0.5
		elseif f = 36: 2t-1.0
		else         : t % ERROR
		fi;
		
		if     t < 0: 0
		elseif t < 1: t
		else        : 1
		fi
		
		% TODO: add a note to getcolor.c
	enddef;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% Scaling factors
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% --> fixed
	% default linewidth in metapost: 0.5bp
	numeric gp_internal_linewidth; gp_internal_linewidth := 0.5bp;

	% --> set globally by user (usually with TeX code)
	% scaling factor for points
	numeric gp_scale_pointsize; gp_scale_pointsize := 1;
	% scaling factor for line widths (for the whole plot)
	numeric gp_scale_linewidth; gp_scale_linewidth := 1;

	% --> calculated based on gnuplot's directives in the middle of plot
	% the true linewidth; equivalent of gp_set_linewidth(1);
	numeric gp_linewidth; gp_linewidth := gp_scale_linewidth*gp_internal_linewidth;

	numeric gp_linetype; gp_linetype := -3;

	% set the scaling factor for point sizes
	def gp_set_pointsize(expr pointsize) =
		gp_scale_pointsize := pointsize;
	enddef;
	% set the scaling factor for line widths
	def gp_set_linewidth(expr linewidth) =
		gp_linewidth := linewidth*gp_scale_linewidth*gp_internal_linewidth;
	enddef;
	% set the linetype:
	% -3: solid with XOR, probably don't need that
	% -2: border, perhaps always with linejoin mitered
	% -1: axis
	%  0 or more : the rest
	def gp_set_linetype(expr linetype) =
		gp_linetype := linetype;
		gp_color_current := gp_color_linetype(linetype);
	enddef;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% FONTS & strings
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% support for textext("...") has been dropped for two reasons:
	% - I don't intend to support it any more
	% - Extremely inefficient anyway (almost useless for gnuplot-generated graphics)
	
	% scalig factor for text labels (relative to the document font)
	% if you set the font to 10pt and use scaling factor 0.7,
	% you'll get 7pt, not 10pt (but using the scaled 10pt design size ;)
	numeric gp_scale_text; gp_scale_text := 1;
	
	% Returns an image with colored text according to current color
	% This only makes sense for mkiv text. Mkii is handled with \sometxt
	% and colors are working properly there. We could be using textext("")
	% in the low level, but we redefined the command just before calling this funtion
	% for text labels, so we really need something more low-level (rawtextext in this case)
	vardef gp_colored_mkiv_text(expr str) =
	
		% since withcolor doesn't work any more, we need to provide a workaround.
		save r, g, b;
		r = redpart   gp_color_current;
		g = greenpart gp_color_current;
		b = bluepart  gp_color_current;

		rawtextext("\colored[r=" & decimal(r) & ",g=" & decimal(g) & ",b=" & decimal(b) & "]{" & str & "}")
	enddef;
	
	% Returns the (image of) text: vertically centered and horizontally aligned
	% according to the parameter align, which can be one of:
	% - gp_align_center
	% - gp_align_left
	% - gp_align_right
	%
	% The code used to support string as input parameter (for textext("...")),
	% but this only complicated the thing and is of no real use any more.
	vardef gp_the_text(expr align, pict) =
		save shift_x, shift_y;
		
		shift_y = -ypart center pict;
		shift_x = -xpart
			% horizontal alignment
			if     align = gp_align_center : center
			elseif align = gp_align_left   : llcorner
			elseif align = gp_align_right  : lrcorner fi
		pict;
		
		(pict shifted (shift_x, shift_y))
	enddef;
	
	% % obsolete code to be removed
	%
	% % horizontal alignment
	% if align = gp_align_center :
	% 	pict := pict shifted (xpart(.5[llcorner pict,lrcorner pict]),0);
	% elseif align = gp_align_left :
	% 	pict := pict shifted (- xpart(llcorner pict),0);
	% elseif align = gp_align_right :
	% 	pict := pict shifted (- xpart(lrcorner pict),0);
	% fi;
	% % Hans wanted to persuade me to make the code shorter
	% % (zero is replicated three times), but I prefer clarity against sparing
	% % two bytes
	% 
	% pict


	% Places text on position "pos":
	% - vertically centered
	% - horizontal alignment is determined from optional arguments - centered by default
	% - angle of rotation from optional parameters
	% - magnification is determined from "gp_scale_text"
	%
	% syntax:
	%   gp_put_text((1cm,2cm),\sometxt[gp]{without optional parameters})
	%   gp_put_text(origin, align_left, angle(15), \sometxt[gp]{with an arbitrary number of optional parameters})
	%
	% The default alignment is centered, the default angle of rotation is zero.
	% \sometxt{} or (theoretically) any picture argument should come last
	def gp_put_text(expr pos)(text t) =
		save arg_angle; arg_angle=0;
		save arg_align; arg_align=gp_align_center;

		save pict; picture pict;
		
		begingroup;
		% save the original meaning of textext
		save textext;
		
		save left, right, center;
		left   = gp_align_left;
		right  = gp_align_right;
		center = gp_align_center;
		
		% dirty trick: let makes the comma behave as semicolon,
		% allowing comma-separated functions in "text t"
		let@=,;

		def angle(expr a) =
			let,=@; let@=,;
			arg_angle := a;
			let,=;;
		enddef;

		% def align_left =
		% 	let,=@; let@=,;
		% 	arg_align := gp_align_left;
		% 	let,=;;
		% enddef;
		% def align_right =
		% 	let,=@; let@=,;
		% 	arg_align := gp_align_right;
		% 	let,=;;
		% enddef;
		% def align_center =
		% 	let,=@; let@=,;
		% 	arg_align := gp_align_center;
		% 	let,=;;
		% enddef;
		
		def align(expr a) =
			let,=@; let@=,;
			arg_align := a;
			let,=;;
		enddef;

		% this is only for mkiv
		% in mkii, \sometxt behaves as an image and has no problems
		% while in mkiv it falls back to textext.drt,
		% and that one has problems if comma gets redefined,
		% so we need to change definition of comma back to its original value first
		%
		% this trick also comes in handy to handle colors & fonts properly
		vardef textext@#(expr txt) =
			let,=@;
			
			gp_colored_mkiv_text(txt)
		enddef ;

		% converts the whole argument into a picture
		%
		% The problem is that \sometxt[gp]{text} is the very last command and cannot be captured as an image otherwise
		% if you know a cleaner solution, please let me know
		vardef dummy(text tt) =
			tt
		enddef;
		pict := dummy(t);

		let,=@;
		endgroup;

		draw (gp_the_text(arg_align, pict) scaled gp_scale_text rotated arg_angle shifted pos) withcolor gp_color_current;
	enddef;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% drawing and filling
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% low-level interface may change !!!
	picture gp_pattern_image[], gp_pattern_current, gp_pattern_type[];
	numeric gp_num_patterns; gp_num_patterns := 11;
	% TODO: redraw the patterns if necessary (if linewidth changes for example)
	numeric gp_pattern_linewidth; gp_pattern_linewidth := .5gp_scale_linewidth*gp_internal_linewidth;
	
	numeric gp_pattern_name_empty; gp_pattern_name_empty := 0;
	numeric gp_pattern_name_full ; gp_pattern_name_full  := 3;

	% default patterns (PostScript-like)
	%
	% 0: empty
	gp_pattern_image[0] := image(
		setbounds currentpicture to unitsquare;
	);
	% 3: full
	gp_pattern_image[3] := image(
	%	fill unitsquare enlarged .1;
	%	setbounds currentpicture to unitsquare;
		fill fullsquare xyscaled (5cm,5cm);
%		fill fullsquare xyscaled (2.5w,2.5h);
	);
	% 4: \
	gp_pattern_image[4] := image( % TODO!!!
		draw ((1,-1)--(-1,1)) scaled 2mm withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare scaled 2mm;
	);
	% 5: /
	gp_pattern_image[5] := image( % TODO!!!
		draw ((-1,-1)--(1,1)) scaled 2mm withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare scaled 2mm;
	);
	% 6: \
	gp_pattern_image[6] := image( % TODO!!!
		draw ((1,-2)--(-1,2)) scaled 2mm withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare scaled 2mm;
	);
	% 7: /
	gp_pattern_image[7] := image( % TODO!!!
		draw ((-1,-2)--(1,2)) scaled 2mm withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare scaled 2mm;
	);
	% 1: 4+5
	gp_pattern_image[1] := image(
		draw gp_pattern_image[4];
		draw gp_pattern_image[5];
	);
	% 2: 4+5, bolj tesno skupaj
	gp_pattern_image[2] := image(
		draw gp_pattern_image[1];
		draw gp_pattern_image[1] shifted (.5bbwidth(gp_pattern_image[1]),0);
	);

	% argument: 2 times radius
	vardef gp_pattern_image_circles(expr d) = image (
		draw fullcircle scaled d withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to fullsquare scaled d;
	) enddef;

	vardef gp_pattern_image_roof(expr d) = image (
		save p; path p; p = fullcircle cutbefore (point 4 of fullcircle);
		draw p scaled d withpen pencircle scaled gp_pattern_linewidth;
		draw p shifted (.5,.5) scaled d withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare shifted (0,-.5) scaled d;
	) enddef;

	vardef gp_pattern_image_brick(expr width, height) = image (
%		save p; path p; p = unitsquare shifted (-.25,-.5) scaled;
		draw unitsquare shifted (-.25,-.5) xyscaled (width,height) withpen pencircle scaled gp_pattern_linewidth;
		draw unitsquare shifted ( .25, .5) xyscaled (width,height) withpen pencircle scaled gp_pattern_linewidth;
		setbounds currentpicture to unitsquare yscaled 2 shifted (-.25,-.5) xyscaled (width,height);
	) enddef;

	for i=0 upto 7:
		gp_pattern_type[i] := gp_pattern_image[i];
	endfor;

	gp_pattern_type[8] := gp_pattern_image_circles(2mm);
	gp_pattern_type[9] := gp_pattern_image_roof(1.5mm);
	gp_pattern_type[10] := gp_pattern_image_brick(2mm,1mm);

	% TODO: filling with a pattern: not implemented yet (implement approximately 8 patterns)
	def gp_fill_pattern(expr p, pattern) =
		save arg_pattern; arg_pattern = pattern mod gp_num_patterns;
		
		if arg_is_transparent = false:
			fill p withcolor gp_color_background;
		fi;
		if pattern = gp_pattern_name_full:
			% fill the area
			fill p withcolor gp_color_current;
		elseif pattern = gp_pattern_name_empty :
			% nothing to do
		else:
			gp_pattern_current := gp_pattern_type[arg_pattern];
			% TODO: check if it exists!

			save maxi; maxi = max(10,bbwidth (p)/bbwidth (gp_pattern_current)+1);
			save maxj; maxj = max(10,bbheight(p)/bbheight(gp_pattern_current)+1);
			draw image (
				for i=-1 upto maxi:
				for j=0 upto maxj:
					draw gp_pattern_current shifted (i*bbwidth(gp_pattern_current),j*bbheight(gp_pattern_current)) shifted llcorner p withcolor gp_color_current;
				endfor;
				endfor;
				clip currentpicture to p;
			);
		fi;
	enddef;

	% fill a closed path with current color with density "density"
	% (0: background color, 1: current color)
	%
	% TODO (once in the future): fill with smooth shading & pattern fill
	%
	% p - path to be filled
	% density - density of the color (between 0 and 1)
	def gp_fill_density(expr p, density) =
		fill (p) withcolor density[gp_color_background,gp_color_current];
	enddef;
	def gp_fill_transparent(expr p, density) =
		fill (p) withcolor transparent(1,density,gp_color_current);
	enddef;
	% filling (default: with density 1)
	% optional parameters:
	%    transparent | (present or not, may be combined with both pattern and the solid fill)
	%    density(float between [0,1])
	%    pattern(number of pattern)
	%
	% If pattern is called at least once, [transparent] pattern will be drawn,
	% otherwise just a [transparent] solid area.
	def gp_fill(text t) =
		% mandatory parameter: path to be stroked
		save arg_path; path arg_path;
		save arg_pattern;
		% default density is 100 %
		save arg_density; arg_density := 1;
		% for transparent density fills or transparent patterns
		% (but transparent patterns are not implemented yet)
		save arg_is_transparent; boolean arg_is_transparent; arg_is_transparent := false;

		% since we redefine "transparent", we need to restore the original macro again
		% before calling gp_fill_transparent, which uses that one
		begingroup;
		save transparent, density, pattern;

		let@=,;

		% this function can be called for transparent (solid) fills or patterns
		def transparent =
			let,=@; let@=,;
			arg_is_transparent := true;
			let,=;;
		enddef;

		def density(expr dens) =
			let,=@; let@=,;
			arg_density := dens;
			let,=;;
		enddef;

		def pattern(expr pat) =
			let,=@; let@=,;
			arg_pattern := pat;
			let,=;;
		enddef;

		% execute the content ("read function arguments")
		let,=;;
		% this will read the first mandatory argument (path) into arg_p and execute any subsequent functions
		arg_path := t;
		let,=@;
		endgroup;

		% pattern fill
		if known arg_pattern:
			gp_fill_pattern(p, arg_pattern);
		% transparent solid fill
		elseif arg_is_transparent:
			gp_fill_transparent(p, arg_density);
		% non-transparent solid fill
		else:
			gp_fill_density(p,arg_density);
		fi;
	enddef;

	def gp_draw(expr p) =
		draw (p) withcolor gp_color_current withpen pencircle scaled gp_linewidth
			% axes should be drawn with only one half of the default linewidth
			% TODO: do we need this to be configurable?
			if gp_linetype = -1: scaled .5 fi
			if gp_use_dashed or (gp_linetype = -1): dashed gp_dash_linetype(gp_linetype) fi;
	enddef;

	def gp_dot(expr x,y) =
		drawdot shifted (x,y) withcolor gp_color_current withpen pencircle scaled gp_linewidth;
	enddef;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%
	%% Poins & Symbols
	%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% should we draw the points using metapost or typeset them using TeX?
	newinternal gp_points_with_metapost, gp_points_with_tex;
	gp_points_with_metapost := 0;
	gp_points_with_tex      := 1;

	numeric gp_points_with;
	% default is to draw the points with metapost rather than typeset them
	% with TeX
	gp_points_with := gp_points_with_metapost;

	% the number of point types
	numeric gp_num_points_with_tex, gp_num_points_with_metapost;

	% returns a path representing a closed n-polygon, starting at upper corner (12 o'clock)
	vardef fullpolygon(expr n) =
		(for i=1 upto n: (up rotated ((i-1)*360/n)) -- endfor cycle)
	enddef;
	% this is used in drawing and filling rectangles (not for points)
	% arguments are lower left and size (size is usually smaller that coordinates - spares some bytes)
	vardef gp_rect(expr ll_corner, size) =
		(ll_corner -- (xpart ll_corner + xpart size,ypart ll_corner) -- (ll_corner shifted size) -- (xpart ll_corner,ypart ll_corner + ypart size) -- cycle)
	enddef;

	%-------------------------%
	% point shape definitions %
	%-------------------------%
	path gp_point_shape[];

	% 0 - plus
	gp_point_shape[0] := (0,0)--(-1,0)--(1,0)--(0,0)--(0,1)--(0,-1)--cycle;
	% 1 - X
	gp_point_shape[1] := (0,0)--(-1,-1)--(1,1)--(0,0)--(-1,1)--(1,-1)--cycle;
	% 2 - star (+ & x)
	gp_point_shape[2] :=
		(0,0)--(-1, 0)--(1, 0)--
		(0,0)--(-1,-1)--(1, 1)--
		(0,0)--(-1, 1)--(1,-1)--
		(0,0)--( 0,-1)--(0, 1)--cycle;
	% 3, 4 - box
	gp_point_shape[3] := (-1,-1)--(1,-1)--(1,1)--(-1,1)--cycle;
	gp_point_shape[4] := gp_point_shape[3];
	% 5, 6 - circle
	gp_point_shape[5] := fullcircle scaled 1.5;
	gp_point_shape[6] := gp_point_shape[5];
	% 7, 8 - triangle
	% scaled is such a way that it's exactly 2 units wide
	gp_point_shape[7] := fullpolygon(3) scaled (1/cosd(30));
	gp_point_shape[8] := gp_point_shape[7];
	% 9, 10 - upside down triangle
	gp_point_shape[9] := gp_point_shape[8] scaled -1;
	gp_point_shape[10] := gp_point_shape[9];
	% 11, 12 - diamond
	gp_point_shape[11] := (-1,0)--(0,-1)--(1,0)--(0,1)--cycle;
	gp_point_shape[12] := gp_point_shape[11];
	% 13, 14 - pentagon
	gp_point_shape[13] := fullpolygon(5) scaled (1/cosd(18));
	gp_point_shape[14] := gp_point_shape[13];

	picture gp_point_pt[];

	% context.trm defines CONTEXT_HTIC = 3.5bp, so points have to match that size
	% all the shapes above are two units big, so we need to scale with 0.5*3.5bp
	%
	% TODO: I should introduce a new variable instead of hardcoding the value
	% TODO: when points are scaled, line width should not scale along
	% TODO: when line widths are scaled, line widths of points should scale as well
	for i=0,1,2,3,5,7,9,11,13:
		gp_point_pt[i] := image(draw gp_point_shape[i]
			scaled 1.75bp withpen pencircle scaled gp_linewidth;);
	endfor;
	for i=4,6,8,10,12,14:
		gp_point_pt[i] := image(filldraw gp_point_shape[i]
			scaled 1.75bp withpen pencircle scaled gp_linewidth;);
	endfor;

	% we have defined 15 point types so far
	gp_num_points_with_metapost := 15;

	%-------------------------%

	% n is the number of symbol, but might a be a figure as well
	vardef gp_the_symbol(expr n) =
		picture pict;
		% using metapost
		if numeric n :
			if n = -1 :
				% point type -1 is always a dot
				pict := image( fill fullcircle scaled 2gp_linewidth; );
			else :
				if gp_points_with = gp_points_with_metapost :
					% TODO
					pict := gp_point_pt[(n mod gp_num_points_with_metapost)];
				else :
					% MK IV; TODO: not sure if relying on context_mlib is safe
					if known context_mlib :
						pict := gp_colored_mkiv_text("\convertnumber{\currentGNUPLOTpointset}{" & decimal(n mod gp_num_points_with_tex + 1) & "}");
					% MK II
					else :
						pict := sometxt((n mod gp_num_points_with_tex) + 1 + 500);
						% XXX: 500 is a hack (see m/t-gnuplot.tex) and might need a fix
					fi;
				fi;
			fi;
		elseif picture n:
			pict := n;
		else:
			pict := nullpicture;
		fi
		pict shifted -center pict
	enddef ;
	% the points have to be scaled slightly more
	def gp_point(expr x, y, n) =
		draw (gp_the_symbol(n) scaled (gp_scale_pointsize) shifted (x,y)) withcolor gp_color_current;
	enddef ;

%	TODO: this needs some more testing and synchronization with gnuplot source code first
%
%	def gp_image_rgb(expr size, ll, ur) =
%		draw bitmapimage (xpart size,ypart size,img) xyscaled (ur shifted -ll) shifted ll;
%	enddef ;
%	def gp_image_rgb_alpha(expr size, ll, ur) =
%		draw bitmapimage (xpart size,ypart size,img) withmask mask xyscaled (ur shifted -ll) shifted ll;
%	enddef ;

	endinput

end.


% How to trick metapost to use comma between macros
%
%beginfig(1);
%
%def do_something(expr xx, yy)(text t) =
%	save c; color c; c = black;
%	save d; numeric d; d = 5pt;
%
%	let@=,;
%
%	def set_color(expr col) =
%		let,=@;
%		let@=,;
%		c := col;
%		let,=;;
%	enddef;
%
%	def set_size(expr size) =
%		let,=@;
%		let@=,;
%		d := size;
%		let,=;;
%	enddef;
%
%	t;
%	let,=@;
%
%	fill fullcircle scaled d shifted (xx,yy) withcolor c;
%enddef;
%
%do_something(1cm,2cm,set_color(blue));
%do_something(2cm,1cm,set_size(10pt));
%% this works OK
%%do_something(2.5cm,1.5cm,set_color(red) set_size(8pt));
%
%% this works OK
%%do_something(2cm,2.5cm,set_color(green);set_size(8pt));
%
%% but the following syntax looks better
%do_something(2.5cm,1.5cm,set_color(blue),set_size(8pt),set_color(red),set_size(2pt));
%
%draw unitsquare scaled 3cm;
%
%endfig;
%end.
