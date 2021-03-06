/* OpenSCAD script to create fully parametric models of shipping containers 

   $Id$

   (C) 2019 by Philipp Reichmuth, philipp.reichmuth@gmail.com 
   This work is licensed under a Creative Commons 
   Attribution-ShareAlike 4.0 International License
   (https://creativecommons.org/licenses/by-sa/4.0/)

   Initial code taken from Parametric Shipping Container
   (C) gundyboyz, https://www.thingiverse.com/thing:1392128,
   licensed under Creative Commons Attribution Unported 3.0
   (https://creativecommons.org/licenses/by/3.0/)
*/

use <fontmetrics.scad>;

// Leave the following constants alone!
// Meaningful names for the indexes into the various vectors
TYPE = 0; DIR = 1; STRING = 1; X = 2; Y = 3; W = 4; FONT_SIZE = 4; H = 5; ROTATE = 5; D = 6;
// Constants for the vector types
OPENING = "O"; WINDOW = "W"; WALL = "D"; 
TEXT_INT = "TI"; TEXT_EXT = "TE"; TEXT_SIDE = "TS"; LOGO_SIDE = "LS";
// Constants for indexing container walls
TOP = 0; FRONT = 1; BACK = 2; RIGHT = 3; LEFT = 4; BOTTOM = 5;
// Constants for assembly styles
INPLACE = 0; FACEUP = 1; FACEDOWN = 2;

// -----------------------------------------------
// Parameter definition begins here

twentyFooter = true;
highcube = false;

// Measurements of shipping container (in meters)
// Shipping container size (external)
EXT_LENGTH = twentyFooter ? 6.058 : 12.19;//6.058;      // Standard lengths: 6.06 for 20', 12.19 for 40'
EXT_WIDTH  = 2.438;      // Standard width:   2.44
EXT_HEIGHT = highcube ? 2.90 : 2.591;      // Standard heights: 2.59 or 2.90 for High Cube

// Model settings
SCALE = 76.2;  // 1:<SCALE> sizing
THICKNESS_WALL = 1.5;        // External wall in mm
THICKNESS_WALL_INT = 1.5;   // Internal wall in mm
TOLERANCE = 0.1; // Tolerance for assembly of walls (excluding frame)


// Container styles:
// 
// General wall styles:
// "none": An empty wall with just the container frame.
// "flat": A flat wall
// "ridges": A corrugated wall with ridges
//
// Wall-specific styles:
// "crossbars": A container bottom with a few broad ridges.
// "door": A simple door: 2 hinges, 1 separator, 1 latch
//
// Interior styles:
// "none": Generate a hollow container
// "infill": Generate a solid container
// "walls": Generate interior parametric walls
// "tank": Generate a tanktainer (works best with no walls)

// This is an incredibly cumbersome way to do it in 
// OpenSCAD, but I hope it is customizer-friendly

STYLE_FRONT="door";
STYLE_BACK="ridges";
STYLE_RIGHT="ridges";
STYLE_LEFT="ridges";
STYLE_TOP="ridges";
STYLE_BOTTOM="flat";
STYLE_FILL="infill";

TEXT_SIDE_FONT = "Impact";
//TEXT_SIDE_WORDS = "Wally Shipping";
//TEXT_SIDE_SIZE = 7;

TEXT_SIDE_WORDS = "Paddy            Trains";
//this is auto-scaled in createText, so not used anymore
TEXT_SIDE_SIZE = 7;//2.1*m2mm(EXT_LENGTH)/len(TEXT_SIDE_WORDS) ;//27 - len(TEXT_SIDE_WORDS)*0.8;
//currently it auto centres
// TEXT_SIDE_POS = [m2mm(EXT_LENGTH)]
// LOGO_SIDE_FILE = "paddington.svg";
// LOGO_SIDE_SIZE = [265.41539,339.24522];
LOGO_SIDE_FILE = "paddington2_bg.svg";
LOGO_BG_FILE = "";
//size, in mm, of SVG (see document properties in inkscape)
LOGO_SIDE_SIZE = [100.54167,137.93611];

/*

I want to produce lots of these containers, so I'm after lots of variation here
Using a photo of a huge stack of these on a cargo ship for inspiration
0 - no door ridges
1 - two ridges evenly spread
*/
DOOR_STYLE=4;

//fractions of height
DOOR_STYLES = [
    [],//none
    [ 1/4, 3/4 ],//two 
    [ 1/3, 2/3 ],//two closer to centre
    [1/4, 2/4, 3/4], //three evenly spaced
    [1/2-1/5, 1/2, 1/2 + 1/5],//three clustered in centre
    [2/10, 4/10, 6/10, 8/10 ], //four near centre
    [2/10, 3/10, 7/10, 8/10 ], //four in two pairs
    [2/10, 4/10,5/10, 6/10, 8/10 ], //five, with three in cetnre
    
];

//as fraction of total height, to be matched with door ridges styles
DOOR_HANDLE_HEIGHTS = [
    [1/4, 1/6, 1/6, 1/4],
    [1/8, 1/6, 1/6, 1/8],
    [1/6, 1/4, 1/6, 1/4],
    [1/3, 1/3, 1/3, 1/3],
    [1/8, 3/16, 1/8, 3/16],
    [2/8, 5/16, 2/8, 5/16],
    [3/25, 3/25, 3/25, 3/25],
    [7/32, 7/24, 7/24, 7/32],
];

DOOR_HANDLE_DIRECTIONS = [
    [false, true, false, true],
    [false, true, false, true],
    [false, true, false, true],
    [true, true, false, false],
    [false, true, false, true],
    [false, true, false, true],
    [true, true, false, false],
    [false, true, false, true],
];



//if true, all in a row, if false, offset heights
DOOR_HANDLES_ALIGNED = true;

// Assembly styles
// "box": a single box
// "lid": box with separate lid
// "parts": separate parts, face up, except bottom.
//          Interior walls will be placed correctly, but
//          ridged container bottoms may be hard to print.
// "facedown": separate parts, face down
// "faceup": separate parts, all face up, including bottom
//           Container bottoms with ridges are easily 
//           printable this way, but interior walls will 
//           not work and will be ignored.
// "custom": custom placement for every part
ASSEMBLY_STYLE = "box";
// Parts displacement distance in mm
PART_D = 3; 

// Custom wall placement
// "inplace" - Generate the wall in place
// "faceup" - Generate the wall separately, face up
// "facedown" - Generate the wall separately, face down
PLACE_TOP = "inplace";
PLACE_FRONT = "faceup";
PLACE_BACK = "faceup";
PLACE_LEFT = "facedown";
PLACE_RIGHT = "faceup";
PLACE_BOTTOM = "inplace"; // inplace = facedown

function customassembly(assembly = [PLACE_TOP, 
  PLACE_FRONT, PLACE_BACK, PLACE_RIGHT, PLACE_LEFT, 
  PLACE_BOTTOM]) = 
  [ for (i=assembly) i=="inplace" ? 0 :
                     i=="faceup" ? 1 :
                     i=="facedown" ? 2 : 0 ];

ASSEMBLY = ASSEMBLY_STYLE == "box" ?    [0,0,0,0,0,0] :
           ASSEMBLY_STYLE == "lid" ?    [1,0,0,0,0,0] :
           ASSEMBLY_STYLE == "parts" ?  [1,1,1,1,1,2] :
           ASSEMBLY_STYLE == "faceup" ? [1,1,1,1,1,1] :
           ASSEMBLY_STYLE == "facedown" ? [2,2,2,2,2,2] :
           ASSEMBLY_STYLE == "custom" ? customassembly() : 
           [0,0,0,0,0,0] ;

FRAME_INSET_X = 0.02;   // X-direction Inset of vertical frame (vis-a-vis corner pieces) 
FRAME_INSET_Y = 0.02;   // X-direction Inset of vertical frame (vis-a-vis corner pieces) 
FRAME_THICKNESS = 0.10; // Frame thickness 

TOP_INSET = 0.02; // Z-direction offset of top panels
SIDE_INSET = 0.03; // Y-direction offset of side panels
SIDE_I = m2mm(SIDE_INSET); // Convert to scale (this needs to be placed here)

/* Supplementary architectural features of the container:
   - Opening: a top-to-bottom cut in a wall
   - Window: a rectangular cut with a frame
   - Wall: an interior wall
   - Text: text set into the inner container bottom.
   Features are defined by coordinates in a local coordinate
   system relative to the wall they're in.
   All units in m.
   Interior text can be placed in X direction only so far.
*/ 

COIN_HOLDER = "none";

PLACE_WINDOWS = false;
PLACE_TEXT_INT = false;
PLACE_TEXT_EXT = false;
PLACE_TEXT_SIDES = len(TEXT_SIDE_WORDS) > 0;
PLACE_LOGO_SIDES = len(LOGO_SIDE_FILE) > 0;
PLACE_SCREWHOLES = true;
PLACE_TUPPENCE_HOLES = COIN_HOLDER == "tuppence";
PLACE_PENNY_HOLES = COIN_HOLDER == "penny";
//in literal mm, not scale metres
screwhole_diameter = 2.0;
screwhole_depth = 10.0;
screwhole_from_edge = twentyFooter  ? 4.75 : 5;
FEATURES = [
     opening(wall=RIGHT, x=0.5, width=4),
     window(wall=LEFT, x=0.75, y=0.8, width=1.8, height=1.7),
     window(wall=BACK, x=0.3, y=2.05, width=1.8, height=0.3),
     window(wall=FRONT, x=0.3, y=1.05, width=1.8, height=1.8),
     wall(dir="x", x=1, y=1.2, length=1.5),
     wall(dir="y", x=2.5, y=0.75, length=1.0),
     text_int(text="Robe", x=0.25, y=2.1, size=6),
     text_int(text="Bed 1", x=3.0, y=1.7, size=8),
     text_ext(text=str("1:",SCALE), x=0.25, y=2.1, size=6),
     text_side(text = TEXT_SIDE_WORDS,x=0.25, y=2.1, size=TEXT_SIDE_SIZE),
     logo_side(text = [LOGO_SIDE_FILE, LOGO_BG_FILE], size=LOGO_SIDE_SIZE)
];

// Color the frame differently
FRAMECOLOR="red";

// Parameter definition ends here
// -----------------------------------------------
// Internal constants begin here

// Dimensions of container corner castings from ISO 1161
// Corner casting body
ISO_1161_CORNER_HEIGHT = 0.12;
ISO_1161_CORNER_LENGTH = 0.18;
ISO_1161_CORNER_WIDTH = 0.16;

// Corner casting body thickness
// So far we have not made the corner castings hollow yet,
// so this is just the depth of the corner holes
ISO_1161_CORNER_THICKNESS = 0.028;

// Corner casting hole dimensions
// X and Y holes are identical
ISO_1161_CORNER_Y_HOLE_LENGTH = 0.078;
ISO_1161_CORNER_Y_HOLE_WIDTH = 0.051;
ISO_1161_CORNER_Z_HOLE_LENGTH = 0.124;
ISO_1161_CORNER_Z_HOLE_WIDTH = 0.0635;  

// Corner casting holes
ISO_1161_CORNER_X_OFFSET = 0.089;  
ISO_1161_CORNER_Y_OFFSET = 0.1;
ISO_1161_CORNER_Z_OFFSET = 0;

// Now we convert all those measurements down to scale
ISO_ch = m2mm(ISO_1161_CORNER_HEIGHT);
ISO_cl = m2mm(ISO_1161_CORNER_LENGTH);
ISO_cw = m2mm(ISO_1161_CORNER_WIDTH);  

ISO_cyhl = m2mm(ISO_1161_CORNER_Y_HOLE_LENGTH);
ISO_cyhw = m2mm(ISO_1161_CORNER_Y_HOLE_WIDTH);
ISO_czhl = m2mm(ISO_1161_CORNER_Z_HOLE_LENGTH);
ISO_czhw = m2mm(ISO_1161_CORNER_Z_HOLE_WIDTH);

ISO_ct = m2mm(ISO_1161_CORNER_THICKNESS);

ISO_cxo = m2mm(ISO_1161_CORNER_X_OFFSET);
ISO_cyo = m2mm(ISO_1161_CORNER_Y_OFFSET);
ISO_czo = m2mm(ISO_1161_CORNER_Z_OFFSET);

// Measurements of simple container door
DOOR_INSET = m2mm(0.1); // Doors are inset 10 cm
SEPARATOR_WIDTH = m2mm(0.05);
SEPARATOR_DEPTH = m2mm(0.05);;
HINGE_LENGTH = m2mm(0.08); // 4 hinges
HINGE_WIDTH = m2mm(0.15);
HINGE_DEPTH = m2mm(0.05);
LATCH_WIDTH = m2mm(0.2);
LATCH_DEPTH = m2mm(0.05); 
LATCH_LENGTH = m2mm(0.1);
LATCH_POS = m2mm(EXT_HEIGHT)/2; // Vertical position

// Ridge parameters
RIDGE_DEPTH = 0.025; // Depth of ridges. Usually between 0.025 and 0.05 (1-2 inches). 0 will get rid of all ridges everywhere
RIDGE_STYLE = "90deg"; // TODO: support different angles
RIDGES_L = EXT_LENGTH > 7 ? 50 : 25; // Number of ridges to create
RIDGES_BOTTOM = EXT_LENGTH > 7 ? 10 : 5; // Number of ridges to create
RIDGES_BOTTOM_RATIO = 0.8; // 80% ridge, 20% bar

// Container sizes in mm in generated model
EXT_L = m2mm(EXT_LENGTH); 
EXT_W = m2mm(EXT_WIDTH);
EXT_H = m2mm(EXT_HEIGHT);

FRAME_I_X = m2mm(FRAME_INSET_X); 
FRAME_I_Y = m2mm(FRAME_INSET_Y);
FRAME_T = m2mm(FRAME_THICKNESS);
TOP_I = m2mm(TOP_INSET);

// Ridge parameters
RIDGE_D = m2mm(RIDGE_DEPTH);
// Width of ridges depending on number on long side
RIDGE_WIDTH = EXT_L / RIDGES_L;   
// Number of ridges on short side, assume equal width
RIDGES_S = EXT_W / RIDGE_WIDTH;
// Ridges at the bottom of containers
RIDGES_BOTTOM_WIDTH = EXT_L / RIDGES_BOTTOM;   

// Helper to fix some topology issues in OpenSCAD
INFINITESIMAL=0.0001;


// ------------ You shouldn't need to change anything past here! -----------

/* Container assembly algorithm:
When we look at the container in X direction,
our container consists of the following parts:
* Bottom (interior structures, no frame parts)
* Front (top and bottom frame bars)
* Back (top and bottom frame bars)
* Left (4 corners, 4 frame bars)
* Right (4 corners, 4 frame bars)
* Top (no frame parts)
* Fill (no frame parts)

Any of these can be...
- in place
- flat
- flat reverse, for easier 3D-printing in some cases

The edges of all walls (but not frame bars & corners) 
are cut off at 45°, so that the container can be
assembled from separate parts.

----- Styles: -----------------------------------
            bottom front left right back top fill
"none"         X     X     X    X     X   X   X
"flat"         X     X     X    X     X   X   
"ridges"       X     X     X    X     X   X
"crossbars"    X
"door"               X                X
"walls"                                       X
"infill"                                      X
"tank"                                        X
---- Supplementary handling ---------------------
frames               X     X    X     X 
openings             X     X    X     X   
text           X  (internal, on top)
annotation     X  (external, on the bottom)

WARNING: When adding new styles, make sure that the
parts placement function accounts for the correct thickness
of the respective walls.
*/
PLACEMENT_TEST = false;
module container() {
  difference() {
    union() {
      placePart(BOTTOM, ASSEMBLY[BOTTOM]) 
        bottom(STYLE_BOTTOM);
      placePart(FRONT, ASSEMBLY[FRONT]) 
        front(STYLE_FRONT);
      placePart(RIGHT, ASSEMBLY[RIGHT]) 
        right(STYLE_RIGHT);
      placePart(LEFT, ASSEMBLY[LEFT]) 
        left(STYLE_LEFT);
      placePart(BACK, ASSEMBLY[BACK]) 
        back(STYLE_BACK);
      placePart(TOP, ASSEMBLY[TOP]) 
        top(STYLE_TOP);
      fill(STYLE_FILL);
      
      if(PLACEMENT_TEST) {
        // Some test cubes to test if we are above the 
        // X-Y plane
        translate(v=[-40,10,-1])
        cube(size=[120,2,1]);  
        translate(v=[28,-40,-1])
        cube(size=[2,120,1]); 
      };
    };
    if(PLACEMENT_TEST) {
      // Intersect with a couple of test cubes to test if 
      // we are below the X-Y plane
      translate(v=[-20,-40,-5])
        cube(size=[10,120,5]);
      translate(v=[10,-40,-5])
        cube(size=[10,120,5]);
      translate(v=[40,-40,-5])
        cube(size=[10,120,5]);
      translate(v=[70,-40,-5])
        cube(size=[10,120,5]);
    };
  };
};

// Placement of wall parts for separate assembly
// This module essentially consists of a list of displacement
// instructions for various walls.
module placePart(wall, style) {
 
  // Vertical displacement for faces (front and back walls)
  SIDE_D = ((wall == RIGHT) && (STYLE_RIGHT == "none")) ||
           ((wall == LEFT) && (STYLE_LEFT == "none")) ?
             ISO_cw : // empty frames: corner width
               THICKNESS_WALL + SIDE_I; // all other walls

  // Vertical displacement for faces (front and back walls)
  FACE_D = ((wall == FRONT) && (STYLE_FRONT == "door")) ||
           ((wall == BACK) && (STYLE_BACK == "door")) ?
             THICKNESS_WALL + DOOR_INSET : // doors
             ((wall == FRONT) && (STYLE_FRONT == "none")) ||
             ((wall == BACK) && (STYLE_BACK == "none")) ?
               FRAME_T : // empty frames
                 THICKNESS_WALL + SIDE_I; // all other walls

  // In place - leave everything as is (box assembly)
  inPlace = [ [[0,0,0],[0,0,0]],
              [[0,0,0],[0,0,0]],
              [[0,0,0],[0,0,0]],
              [[0,0,0],[0,0,0]],
              [[0,0,0],[0,0,0]],
              [[0,0,0],[0,0,0]] ];
              
  // Face up - place walls ridges up, smooth side down    
  faceUp = [
    [ [0,EXT_W+PART_D,-EXT_H+THICKNESS_WALL+TOP_I],[0,0,0] ], // top
    [ [-EXT_H-PART_D,0,FACE_D],[0,90,0] ], // front
    [ [EXT_L+EXT_H+PART_D,0,-EXT_L+FACE_D],[0,-90,0] ], // back
    [ [0,-EXT_H-PART_D,SIDE_D],[-90,0,0]  ], // right
    [ [0,2*EXT_W+2*PART_D+EXT_H,-EXT_W+SIDE_D],[90,0,0] ],  // left
    [ [0,EXT_W,THICKNESS_WALL], [180,0,0] ] // bottom
  ];  

  // Face down - place walls ridges down, smooth side up
  faceDown = [
    [ [0,2*EXT_W+PART_D,EXT_H-TOP_I],[180,0,0] ], // top
    [ [-PART_D,0,0],[0,-90,0] ], // front
    [ [EXT_L+PART_D,0,EXT_L],[0,90,0] ], // back
    [ [0,-PART_D,0],[90,0,0] ], // right
    [ [0,2*EXT_W+2*PART_D,EXT_W],[-90,0,0] ], // left
    [ [0,0,0], [0,0,0] ] // bottom
  ]; 
  
  orientation = [inPlace, faceUp, faceDown];
  
  translate(orientation[style][wall][0])
    rotate(orientation[style][wall][1])
      children();    
};

module side(style=STYLE_RIGHT, features=FEATURES, dir=RIGHT) {
  // By default this generates a "right" side.
  // To generate left sides, we need to translate &
  // rotate it into the correct position.
  difference() {
    union() {
      if (style == "ridges") {
          side_ridges();
      } else if (style == "flat") {
          side_flat();
      } else if (style == "none") {
          // ISO 1161 frame only
          side_frame();
      };
      // Generate window frames
      if (PLACE_WINDOWS) {
        for (feature = FEATURES) {
           createFrame(feature, dir);
        };
      };
      if (PLACE_TEXT_SIDES) {
        for (text = features) {
          if (text[TYPE] == TEXT_SIDE) {
            createText(text);
          };
        };
      };
      if (PLACE_LOGO_SIDES) {
        for (logo = features) {
          if (logo[TYPE] == LOGO_SIDE) {
            createLogo(logo);
          };
        };
      };
    }; // union
    // Generate cutouts
    if (PLACE_WINDOWS) {
      for (feature = FEATURES) {
          createCutout(feature, dir);
      };
    };    
  }; // difference
};

module right(style=STYLE_RIGHT, features=FEATURES) {
      side(style, features, RIGHT); 
}; 

module left(style=STYLE_LEFT, features=FEATURES) {
  // Translate & rotate the default "right" side, so that it
  // becomes a "left" side
  translate(v=[EXT_L, EXT_W, 0])
    rotate([0,0,180])
      side(style, features, LEFT);
};

module face(style=STYLE_FRONT, features=FEATURES, dir=FRONT) {
  // By default this generates a "front" face.
  // To generate "back" faces, we need to translate & rotate it into the correct position.
  difference() {
    union() {
      if (style == "door") {
          face_door();
      } else if (style == "ridges") {
          face_ridges();
      } else if (style == "flat") {
          face_flat();
      } else if (style == "none") {
          // Frame only
          face_frame();
      };
      // Generate window frames
      if (PLACE_WINDOWS) {
        for (feature = FEATURES) {
           createFrame(feature, dir);
        };
      };
    }; // union
    // Generate cutouts
    if (PLACE_WINDOWS) {
      for (feature = FEATURES) {
          createCutout(feature, dir, offsetX=DOOR_INSET);
      };
    };    
  }; // difference
};

module front(style=STYLE_FRONT, features=FEATURES) {
  face(style, features, FRONT);
};

module back(style=STYLE_BACK, features=FEATURES) {
  // Translate & rotate the default "front" face, so that it
  // becomes a "back" face
  translate(v=[EXT_L, EXT_W, 0])
    rotate([0,0,180]) 
      face(style, features, BACK);
}

module top(style=STYLE_TOP) {
    if (style == "ridges") {
        top_ridges();
    } else if (style == "flat") {
        top_flat();
    } else if (style == "none") {
        // nothing
    };    
};

module base_holes(screwhole_diameter, screwhole_from_edge, screwhole_depth, extraForFortyFeet = true){
    translate([screwhole_from_edge,EXT_W/2,0])
        cylinder(h=screwhole_depth*2, r=screwhole_diameter/2, $fn=200, center=true);
    
    translate([EXT_L - screwhole_from_edge,EXT_W/2,0])
        cylinder(h=screwhole_depth*2, r=screwhole_diameter/2, $fn=200, center=true);
    echo("screwholes distance ", EXT_L - screwhole_from_edge - screwhole_from_edge);
    
    if(!twentyFooter && extraForFortyFeet){
        //extra screwholes
        
        translate([screwhole_from_edge+70,EXT_W/2,0])
        cylinder(h=screwhole_depth*2, r=screwhole_diameter/2, $fn=200, center=true);
    
    translate([EXT_L - screwhole_from_edge - 70,EXT_W/2,0])
        cylinder(h=screwhole_depth*2, r=screwhole_diameter/2, $fn=200, center=true);
    echo("screwholes distance ", EXT_L - screwhole_from_edge - screwhole_from_edge);
    }
}

module screwholes(){
	base_holes(screwhole_diameter, screwhole_from_edge, screwhole_depth);
}

module tuppence_holes(){
	base_holes(25.9+0.4, 23, 2.03*2+0.9, false);
}

module penny_holes(){
	base_holes(20.3+0.4, 23, 1.65*4+0.9, false);
}

module bottom(style=STYLE_BOTTOM, features=FEATURES) {
  difference() {
    if (style == "crossbars") {
        bottom_crossbars();
    } else if (style == "ridges") {
        bottom_ridges();
    } else if (style == "flat") {
        bottom_flat();
    } else if (style == "none") {
        // nothing
    };
    // superimpose internal text here if we want it
    if (PLACE_TEXT_INT) {
      for (text = features) {
        if (text[TYPE] == TEXT_INT) {
          createText(text);
        };
      };
    };
    // superimpose bottom text here if we want it
    if (PLACE_TEXT_EXT) {
      for (text = features) {
        if (text[TYPE] == TEXT_EXT) {
          createText(text);
        };
      };
    };
    if (PLACE_SCREWHOLES) {
        screwholes();
    }
	if(PLACE_TUPPENCE_HOLES){
		tuppence_holes();
	}
	if(PLACE_PENNY_HOLES){
		penny_holes();
	}
  };
};

module fill(style=STYLE_FILL, features=FEATURES) {
    if (style == "walls") {
        // generate interior walls here
        for (wall = features) {
            createWall(wall);
        }
    } else if (style == "infill") {
        fill_infill();
    } else if (style == "tank") {
        fill_tank();
    } else if (style == "none") {
        // nothing
    };
};

// Side wall styles
// Side frame
module side_frame(h = EXT_H, l = EXT_L, w = EXT_W,
                   t = FRAME_T, 
                   inset = [FRAME_I_X, FRAME_I_Y, 0],
                   ch = ISO_ch, cl = ISO_cl, cw = ISO_cw) {
    // Generate parallel beams from offsets & length    
    beams = concat(
      // Horizontal
      mve( [ [cl-inf(),0,0], 
             [cl-inf(),0,h-t] ], 
           [l-2*cl+inf(2), t, t] ),
      // Vertical
      mve( [ [inset[0],inset[1],ch-inf()],
             [l-t-inset[0],inset[1],ch-inf()]],
           [t-inset[0],t-inset[1],h-2*ch+inf(2)]) );
    
    for(i = beams) {
      translate(i[0])
        color(FRAMECOLOR)
          cube(size=i[1]);}

    // Corners
    for(i = [ [[0,0,0],[0,0,0],[0,0,0]],
              [[l,0,0],[1,0,0],[0,0,0]], 
              [[0,0,h],[0,0,0],[0,0,1]],
              [[l,0,h],[1,0,0],[0,0,1]]  
            ]) {
        translate(i[0])
          mirror(i[1]) mirror(i[2])
            color(FRAMECOLOR)
              corner();
    };
};
    
// Side flat wall
module side_flat(inset = SIDE_I, 
                  t=FRAME_T, l=EXT_L, h=EXT_H, 
                  wall=THICKNESS_WALL) {
    side_frame(); 
    intersection() {
      translate(v=[t, inset, t])
        cube(size=[l-2*t, wall, h-2*t]);
      // corners cut at 45° for easier assembly
      translate(v=[0,0,h])
        rotate([-90,0,0])                      
          pyramid45(l,h); 
      };
};

// Side wall with ridges
module side_ridges(inset = SIDE_I,
                    h=EXT_H, t=FRAME_T,
                    count=RIDGES_L, 
                    rd=RIDGE_D, rw=RIDGE_WIDTH) {
    difference() {
      side_flat(inset); 
      // Generate simple rectangular ridges
      for (i = [1 : count - 1]) {
        translate (v=[(i*rw) - (rw/4), inset, t])
          ridge(rw / 2, rd, h-2*t);
        }
    };
}

// Face styles

// Frame only
module face_frame(offset = SIDE_I, //ignored
                  w=EXT_W, h=EXT_H,
                  t=FRAME_T, cw=ISO_cw){
    for(i = [ [0,cw,0],
              [0,cw,h-t] ]) {
      translate(i)
        color(FRAMECOLOR)
          cube(size=[t, w-2*cw, t]);
    }
};

// Flat wall
module face_flat(offset = SIDE_I,
                 w=EXT_W, h=EXT_H,
                 t=FRAME_T, cw=ISO_cw,
                 wall=THICKNESS_WALL) {
    face_frame(offset, w, h, t, cw);
    intersection() {
      translate(v=[offset, t, t]) 
        cube(size=[wall, w-2*t, h-2*t]);
      // corners cut at 45° for easier assembly
      translate(v=[0,0,h])
        rotate([0,90,0])
          pyramid45(h, w);
    };
};

// Front wall with vertical ridges
module face_ridges(offset = SIDE_I,
                   w=EXT_W, h=EXT_H,
                   t=FRAME_T, cw=ISO_cw,
                   wall=THICKNESS_WALL,
                   count=RIDGES_S,
                   rd=RIDGE_D, rw=RIDGE_WIDTH){
    difference() {
      face_flat();
      for (i = [0 : count - 1]) {
        translate (v=[offset, (i*rw) - (rw/4), t])
          ridge(rd, rw/2, h-2*t);
      }
    };
};

// Simple front door: 2 doors, 4 ridges, 4 hinges, 
//                    center separator, latch
module face_door(offset = DOOR_INSET,
                 w=EXT_W, h=EXT_H,
                 t=FRAME_T, cw=ISO_cw,
                 wall=THICKNESS_WALL,
                 rd=RIDGE_D, rw=RIDGE_WIDTH, // Ridges 
                 sd=SEPARATOR_DEPTH, // Door separator
                 sw=SEPARATOR_WIDTH,
                 hl=HINGE_LENGTH,
                 hw=HINGE_WIDTH, hd=HINGE_DEPTH,
                 lp=LATCH_POS, ll=LATCH_LENGTH, // Latch
                 lw=LATCH_WIDTH, ld=LATCH_DEPTH,
                ) {
  face_frame(offset, w, h, t, cw);
  // Face plane with 45" cutoff
  intersection() {  
    union() {
      // Generate corrugated door
      difference() {
        // Door plane
        translate(v=[offset, t, t]) 
          cube(size=[wall, w-2*t, h-2*t]);
        // Ridges in door
        /*for(i = [ [offset, t, hpl+hl/2 - rw*3/2],
                  [offset, t, hpl+hl/2 + rw*3/2],
                  [offset, t, hph+hl/2 - rw*3/2],
                  [offset, t, hph+hl/2 + rw*3/2]
                  ] ) {
          translate(v = i)
            ridge(rd, w-2*t, rw/2);
        }
          */
          door_ridge_height = rw/2;
          //distance between hinges and centre bit of door
          internal_door_width = w - t*2;
          door_centre_wide = internal_door_width*0.1;
          door_ridge_width = internal_door_width/2 - hw - door_centre_wide/2;
          union(){
              if(len(DOOR_STYLES[DOOR_STYLE]) > 0){
                  //ridges in doors
                  intersection(){
                      
                      
                      
                      for(ridge_height = DOOR_STYLES[DOOR_STYLE] ) {
                              translate(v = [offset, t, ridge_height*h - door_ridge_height/2])
                                ridge(rd, w-2*t, door_ridge_height);
                          }
                    
                    //only want ridges in the middles of both doors
                    union(){
                        translate([0,t+hw])cube([wall*10,door_ridge_width,h]);
                        translate([0,w-t-door_ridge_width-hw])cube([wall*10,door_ridge_width,h]);
                    }
                }
            }
            //and a slot down the middle to make it look like two doors
            translate([t/3,w/2,0])rotate([0,0,45])cube([t,t,h*3],center=true);
        }
      };
      // this was a "Door separator" now it's the 4 locking mechanisms
      lockingPositions = [w/4,
                                w/2-w/6+w/12 + w/96,
                                w/2+w/6-w/12 - w/96,
                          w-w/4
                         ];
      for(i = [0:3]){
          y = lockingPositions[i];
          
          translate(v=[offset-sd, y-sw/2, t])
             cubecylinder(size=[sd, sw, h-2*t]);
          //extra cube behind them so these aren't floating above the ridges
           translate(v=[offset, y-sw/2, t])
             cube([sd, sw, h-2*t]);
           handle_width = w/12;
          //handles for the locking mechanism
          translate(v=[offset-sd, DOOR_HANDLE_DIRECTIONS[DOOR_STYLE][i] ? y-handle_width : y, h*DOOR_HANDLE_HEIGHTS[DOOR_STYLE][i]])
             cube([sd*2, handle_width , sw*0.75]);
      }
      
      
      
      
      // Hinges
      for(y = [t, w-t-hw]) {
        for(z = [0:4]) {
          translate(v=[offset-hd,y,h/8+z*h/4 - hl/2])
            cube(size=[hd,hw,hl]);
        };
      };
      // Lock
      translate(v=[offset-ld,w/2-lw/2,lp])
        rotate([-90,0,0])
          cube([ld,ll,lw]);  
    }; // union
    // corners cut at 45° for easier assembly
    translate(v=[0,0,h])
      rotate([0,90,0])
        pyramid45(h, w);
  }; // difference
};

// Top styles
// Flat top
module top_flat(offset = TOP_I,
                h=EXT_H, l=EXT_L, w=EXT_W,
                ch=ISO_ch,cl=ISO_cl,cw=ISO_cw,
                t=FRAME_T, wall=THICKNESS_WALL) {

    // Figure out how to treat tolerance:
    // * TOLERANCE when separate objects
    // * -inf() when together, to avoid geometry errors 
    //   in SCAD            
    delta = (PLACE_TOP != "regular") ? TOLERANCE : -inf();

    difference() {
      intersection() {
        translate(v=[0,0,h-wall-offset])
          cube(size=[l,w,wall]);
        // corners cut at 45° for easier assembly
        translate(v=[0,0,h]) 
          mirror([0,0,1])
            pyramid45(l,w); 
      };
      // For the top cover we need different geometry:
      // - No overhangs
      // - Spare offset around corners easier assembly
      // This is so that we can put the top cover on the 
      // container more easily when printed separately.
      //
      // Exclude corners
      for(i = [ [0,0,0], 
                [l-cl-delta,0,0],
                [0,w-cw-delta,0],
                [l-cl-delta,w-cw-delta,0] ]) {
        translate(i)
          cube(size=[cl+delta,cw+delta,h]); // Full height 
      };
      // Exclude frame bars
      cube(size=[l, t+delta, h]);
      cube(size=[t+delta, w, h]);
      translate([l, w, 0])
        rotate([0,0,180]) {
          cube(size=[l, t+delta, h]);
          cube(size=[t+delta, w, h]);};
  };
};

// Ridged top
module top_ridges(offset = TOP_I,
                h=EXT_H, l=EXT_L, w=EXT_W,
                ch=ISO_ch,cl=ISO_cl,cw=ISO_cw,
                t=FRAME_T, wall=THICKNESS_WALL,
                count=RIDGES_L, 
                rd=RIDGE_D, rw=RIDGE_WIDTH) {
    difference() {
      top_flat(offset, h, l, w, ch, cl, cw, t, wall); 
      // Generate ridges
      for (i = [0 : count - 1]) {
        translate (v=[(i*rw) - (rw/4), offset, h-offset-rd])
          ridge(rw / 2, w, rd);
        }
    };
};

// Bottom styles
// Flat bottom
module bottom_flat(l=EXT_L, w=EXT_W, h=EXT_H,
                   t=FRAME_T, 
                   wall=THICKNESS_WALL,
                   ch=ISO_ch, cl=ISO_cl, cw=ISO_cw
                  ) { 
    difference() {
      intersection() {
        cube(size=[l, w, wall]);
        // corners cut at 45° for easier assembly
        pyramid45(l, w); 
      };
      // All exclusions full height, to be assembly-friendly
      // Exclude corners, full height
      for(i = [ [0,0,0], 
                [l-cl,0,0],
                [0,w-cw,0],
                [l-cl,w-cw,0] ]) {
        translate(i)
          cube(size=[cl,cw,h]); 
      };
      // Exclude frame bars, full height
      cube(size=[l, t, h]);  
      cube(size=[t, w, h]);
      translate([l, w, 0])
        rotate([0,0,180]) {
          cube(size=[l, t, h]);
          cube(size=[t, w, h]);};
    };
};

// Bottom with wide-spaced ridges
module bottom_crossbars() {
  difference() {
    bottom_flat();
    // Ridges along bottom
    translate(v=[RIDGES_BOTTOM_WIDTH*(1-RIDGES_BOTTOM_RATIO)/2,0,0])
      for (i = [0 : RIDGES_BOTTOM - 1]) {
        translate (v=[(i*RIDGES_BOTTOM_WIDTH), FRAME_T, 0])
        cube(size=[RIDGES_BOTTOM_WIDTH * RIDGES_BOTTOM_RATIO, EXT_W - 2*FRAME_T, RIDGE_D]);
      };
  };       
};

// Bottom with ordinary ridges
module bottom_ridges() {
    difference() {
        bottom_flat();
        // Ridges along bottom
          for (i = [0 : RIDGES_L - 1]) {
            translate (v=[(i*RIDGE_WIDTH) - (RIDGE_WIDTH / 4), FRAME_T, 0])
            cube(size=[RIDGE_WIDTH / 2, EXT_W - 2*FRAME_T, RIDGE_D]);
        };
    };       
};

// Fill styles
// Filled-in container, no hollow model
module fill_infill(offset = THICKNESS_WALL) {
  difference(){
    translate(v=[offset-inf(), offset-inf(), offset-inf()])
      cube(size=[EXT_L-2*offset+inf(2), 
                 EXT_W-2*offset+inf(2), 
                 EXT_H-2*offset+inf(2)]);
      if(PLACE_SCREWHOLES){
          screwholes();
      }
	  if(PLACE_TUPPENCE_HOLES){
		tuppence_holes();
		}
	if(PLACE_PENNY_HOLES){
			penny_holes();
		}
  }
};

// Single tank for tanktainer
// Possibly customize this more to allow different shapes
module fill_tank(rounding = 5) {
    center = [EXT_L/2, EXT_W/2, EXT_H/2];
    facecenter = [0, EXT_W/2, EXT_H/2];
    minkowski() {
      intersection() {
        // Faces follow a sphere shape 
        translate(v=center)
          sphere(r=EXT_L/2-rounding, $fn=100);
        // Sides follow a cylinder shape
        translate(v=facecenter)
          rotate([0,90,0])
            cylinder(r=EXT_W/2-rounding, h=EXT_L, $fn=50);
      };
      // The sphere/cylinder boundary is rounded off
      sphere(r=rounding, $FN=100);
    };
};


// Some geometric primitives

// 45" pyramid over a rectangle of length l and width w
// TODO: this needs to accept a delta value for either 
//       positive or negative tolerance
module pyramid45(l = EXT_L, w = EXT_W, d=0){
    polyhedron(
       points = [ [d  ,d  ,d], [l-d,d,  d], 
                  [l-d,w-d,d], [d,  w-d,d], // 0,1,2,3: base
                  [w/2-d/2,   w/2, w/2-d/2], 
                  [l-w/2-d/2, w/2, w/2-d/2] // 4,5: top
                ],
       faces =  [ [0,1,2,3],  // base
                  [4,5,1,0],  // right
                  [5,2,1],    // back
                  [5,4,3,2],  // left
                  [3,4,0] ],  // front
       convexity = 2
    );
}

// Half cube, half circle
// Cylinder half to the front, cube to the back
module cubecylinder(size = [10,5,20], faces=20) {
  union(){
    translate(v=[size[1]/2, size[1]/2, 0])
      cylinder(r=size[1]/2, h=size[2], $fn=faces);
    translate(v=[size[1]/2, 0, 0])
      cube(size=[size[0]-size[1]/2, size[1], size[2]]);
  }
}

// Container-related geometric helpers
// Ridges of various styles
module ridge(x, y, z, style=RIDGE_STYLE) {
    if(style=="90deg") { // Simple 90° ridge is a cube
      cube(size=[x, y, z]);
    }; 
    // Add other ridge styles here, e.g. customizable angles
};

// ISO 1161 container corner casting - vertical hole
module corner_hole_Z( thickness = ISO_ct ) {
  intersection(){
    cylinder(h=thickness,r=ISO_czhl/2, $fn=20);
    translate(v=[ISO_czhl/-2,ISO_czhw/-2,0])
      cube(size=[ISO_czhl, ISO_czhw, thickness]);  
      };
};

// ISO 1161 container corner casting - front hole
module corner_hole_X(thickness = ISO_ct ) {
  corner_hole_Y(thickness);
}

// ISO 1161 container corner casting - side hole
module corner_hole_Y(thickness = ISO_ct ) {
  hull() {
    translate(v=[(ISO_cyhl-ISO_cyhw)/-2,0,0])
      cylinder(h=thickness, r=ISO_cyhw/2, $fn=20);
    translate(v=[(ISO_cyhl-ISO_cyhw)/2,0,0])
      cylinder(h=thickness, r=ISO_cyhw/2, $fn=20);
  }
};

// ISO 1161 container corner casting
module corner() {
    difference() {
      cube(size=[ISO_cl, ISO_cw, ISO_ch]);
      // X hole
      translate(v=[0,ISO_cxo,m2mm(ISO_1161_CORNER_HEIGHT)/2])
        rotate([0,90,0])
          translate(v=[m2mm(0.005),0,inf(-1)])
            corner_hole_X();
      // Y hole
      translate(v=[ISO_cyo,0,ISO_ch/2])
        rotate([-90,90,0])
          translate(v=[m2mm(0.005),0,inf(-1)])
            corner_hole_Y();
      // Z hole
      translate(v=[ISO_cyo, ISO_cxo,0])  
        corner_hole_Z();
      // Hollow core
      // Add this if necessary
    };
};

// Helper functions - Generate various container features

// Create text embedded in the floor
// TODO: implement rotation
module createText(text) {
  // Text at the top of the floor
  if (text[TYPE] == TEXT_INT) {
    translate ([m2mm(text[X]), m2mm(text[Y]), THICKNESS_WALL * 0.75])
    linear_extrude(height = THICKNESS_WALL) {
      text(text = text[STRING],
      font = "Arial",
      size = text[FONT_SIZE],
      halign = "left",
      valign = "top");
    };
  // Text at the bottom of the floor
  } else if (text[TYPE] == TEXT_EXT) {
    translate ([EXT_L-m2mm(text[X]), m2mm(text[Y]), 0])
      mirror([1,0,0])
        linear_extrude(height = THICKNESS_WALL * 0.25) {
          text(text = text[STRING],
          font = "Arial",
          size = text[FONT_SIZE],
          halign = "left",
          valign = "top");
    };
  }else if(text[TYPE] == TEXT_SIDE){

    length = measureText(text[STRING], font=TEXT_SIDE_FONT, size=text[FONT_SIZE]);
    scaleBy = (EXT_L-5) / length;
     translate (v=[EXT_L/2, SIDE_I+RIDGE_D*1.5, EXT_H/2])
      rotate([90,0,0])
        scale([scaleBy,scaleBy,1])
        linear_extrude(height = RIDGE_D*2) {
         text(text = text[STRING],
          font = TEXT_SIDE_FONT,
          size = text[FONT_SIZE],
          halign = "center",
          valign = "center");
        }
  };
};

module createLogo(logo){
  logo_lines = logo[STRING][0];
  logo_bg = logo[STRING][1];
  logo_aspect = logo[FONT_SIZE][0]/logo[FONT_SIZE][1];
  container_aspect = EXT_L/EXT_H;
  //scale by height or width so it will fit
  scaleby = logo_aspect < container_aspect ? (EXT_H-5)/logo[FONT_SIZE][1] : (EXT_L-5)/logo[FONT_SIZE][0];
  translate (v=[EXT_L/2, SIDE_I+RIDGE_D*1.5, EXT_H/2])
    rotate([90,0,0]){
      if(len(logo_lines) > 0){
        linear_extrude(height = RIDGE_D*2)
        //offset as hack to cope with self-intersecting SVG (http://forum.openscad.org/problem-with-SVG-import-td31295.html)
         scale([scaleby,scaleby,1])offset(0.01)import(logo_lines, center=true);
      }
      if(len(logo_bg) > 0){
        linear_extrude(height = RIDGE_D*1.5)
         scale([scaleby,scaleby,1])offset(0.01)import(logo_bg, center=true);
      }
    }
  }



// Create cutouts (applies to openings and windows)
module createCutout(opening, direction = "", offsetX = 0, offsetY = 0) {
  // Optionally limit generating cutouts to a single wall
  if (direction == "" || direction == opening[DIR]) {    
    if (opening[TYPE] == WINDOW || opening[TYPE] == OPENING) {
      translate (v=[x(opening), y(opening), z(opening)])
        cube(size=[w(opening)+offsetX, 
                   d(opening)+offsetY, 
                   h(opening)]);
    };
  };
}

// Create the frame for a window
module createFrame(opening, direction="") {
  // Optionally limit frame generation to a single wall
  if (direction == "" || direction == opening[DIR]) {
    if (opening[TYPE] == WINDOW) {
        
      echo("Placing stuff in direction", opening[DIR]);     
      placement = 
        opening[DIR] == LEFT || opening[DIR] == RIGHT ? 
          [[x(opening) - 1, y(opening), z(opening) - 1], 
           [w(opening) + 2, d(opening), h(opening) + 2]] :
        opening[DIR] == BACK || opening[DIR] == FRONT ?
          [[x(opening), y(opening) - 1, z(opening) - 1],
           [w(opening), d(opening) + 2, h(opening) + 2]] :
//           [w(opening), d(opening) + 2, h(opening) + 2]] :
        [[],[]];
        
      cutoff = 
        opening[DIR] == LEFT || opening[DIR] == RIGHT ? 
          [[0,0,EXT_H], [-90,0,0], [EXT_L,EXT_H], 
           [EXT_L, FRAME_THICKNESS, EXT_H]] : 
        opening[DIR] == BACK || opening[DIR] == FRONT ?
          [[0,0,EXT_H], [0,90,0], [EXT_W, EXT_H], 
           [FRAME_THICKNESS, EXT_W, EXT_H] ] :
        [ [], [], [], [] ];

      // When generating window frames, we need to make 
      // sure that that they also follow the internal 45° 
      // edge cutoff (for easier assembly)
      intersection() {
        // The frame is just a cube, we cut out the 
        // opening for the window separately.
        translate(v=placement[0])
          cube(size=placement[1]);
        union() {
          // Cut off wall edges at 45° internally
          translate(v=cutoff[0])
            rotate(cutoff[1])                      
              pyramid45(cutoff[2][0], cutoff[2][1]); 
          // Leave frame on the outside as is
          cube(size=cutoff[3]);
        }; // union
      }; // intersection
    }; // if
  }; // if
}

// Create an internal wall
// Note: Create internal walls only if the bottom is
// placed right face down.
module createWall(wall) {
    if ((wall[TYPE] == WALL) && (ASSEMBLY[BOTTOM] != 1)) {
        if (wall[DIR] == "x") {
            translate (v=[m2mm(wall[X]), m2mm(wall[Y]), THICKNESS_WALL])
            cube(size=[m2mm(wall[W]), THICKNESS_WALL_INT, 
              EXT_H-THICKNESS_WALL*2-TOP_I-TOLERANCE]); 
        }
        if (wall[DIR] == "y") {
            translate (v=[m2mm(wall[X]), m2mm(wall[Y]), THICKNESS_WALL])
            cube(size=[THICKNESS_WALL_INT, m2mm(wall[W]), 
              EXT_H-THICKNESS_WALL*2-TOP_I-TOLERANCE]);
        }
    }
}

// Converting m to mm and to scale
function m2mm(m) = m * 1000 / SCALE;

// Return an infinitesimally small value, useful for avoiding some manifold issues in OpenSCAD
function inf(n=1) = n*INFINITESIMAL;

// List generators
// From [a,b] and x generate [[a,x],[b,x]]
function mve (v,e) = [ for (i = v) [i, e] ];        
// From a and [x,y] generate [[a,x],[a,y]]
function mev (e,v) = [ for (i = v) [e, i] ];

/* Container features for windows, openings and walls
   are specified in a coordinate system relative to the
   wall they're in, so they need to be converted into 
   absolute coordinates. 
   TODO: zero in the local coordinate system needs to 
   exclude the frame bars, as we can't place openings there.
*/
function x(vec) = 
  vec[DIR]==RIGHT || vec[DIR]==LEFT ? m2mm(vec[X]) :
    vec[DIR]==FRONT || vec[DIR]==BACK ? 0 : 999;
function y(vec) =
  vec[DIR]==RIGHT || vec[DIR]==LEFT ? 0 :
    vec[DIR]==FRONT || vec[DIR]==BACK ? 
      EXT_W - m2mm(vec[W]) - m2mm(vec[X]) : 999;
function z(vec) = 
  vec[Y] == 0 ? m2mm(FRAME_THICKNESS) : m2mm(vec[Y]);
function w(vec) =
  vec[DIR]==RIGHT || vec[DIR]==LEFT? m2mm(vec[W]) :
      vec[D];
function h(vec) = m2mm(vec[H]);
function d(vec) = // Depth of cut
  vec[DIR]==RIGHT || vec[DIR]==LEFT ? vec[D] :
      m2mm(vec[W]);

// Helpers for easier definition of architectural features
function opening(wall, x, width) = 
  [OPENING, wall, x, 0, width, EXT_HEIGHT-2*FRAME_THICKNESS, THICKNESS_WALL+SIDE_I];
function window(wall, x, y, width, height) = 
  [WINDOW, wall, x, y, width, height, THICKNESS_WALL+SIDE_I];
function wall(dir, x, y, length) = 
  [WALL, dir, x, y, length];
function text_int(text, x, y, size, rotate) = 
  [TEXT_INT, text, x, y, size, rotate];
function text_ext(text, x, y, size, rotate) = 
  [TEXT_EXT, text, x, y, size, rotate];
function text_side(text, x, y, size, rotate) = 
  [TEXT_SIDE, text, x, y, size, rotate];
function logo_side(text, size, rotate) = 
  [LOGO_SIDE, text, 0, 0, size, rotate];

// Create all the model objects...
echo(str("Container size ", EXT_L, "mm x ", EXT_W, "mm x ", EXT_H, "mm"));
container();