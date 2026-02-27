/* 
   PROJECT: Parametric PCB Enclosure v1.0
   AUTHOR: Einojuhani Nurmi
   DESCRIPTION: 
   A fully parametric box with a snap-fit lid and mounting posts.
   Demonstrates difference logic, tolerance handling, and modular design.
*/

// --- PARAMETERS ---

// Inner dimensions of the enclosure
box_width  = 80; 
box_length = 50; 
box_height = 30;

// Wall and material settings
wall_thickness = 2;
corner_radius  = 4;
tolerance      = 0.2; // Gap for 3D printing fit

// Mounting posts
post_diameter = 6;
hole_diameter = 2.5;

// Resolution for curves
$fn = 60;

// --- MODULES ---

// Creates a rounded box shape (Reusable helper)
module rounded_block(x, y, z, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=z, r=r);
        translate([x-r, r, 0]) cylinder(h=z, r=r);
        translate([x-r, y-r, 0]) cylinder(h=z, r=r);
        translate([r, y-r, 0]) cylinder(h=z, r=r);
    }
}

// The main body of the box
module housing_body() {
    difference() {
        // Outer Shell
        rounded_block(
            box_width + wall_thickness*2, 
            box_length + wall_thickness*2, 
            box_height, 
            corner_radius
        );
        
        // Inner Cavity (hollow out)
        translate([wall_thickness, wall_thickness, wall_thickness])
        rounded_block(
            box_width, 
            box_length, 
            box_height, 
            corner_radius - wall_thickness
        );
        
        // Ventilation Slots (Loop generation)
        for(i = [10 : 5 : box_width - 10]) {
            translate([i + wall_thickness, -1, box_height/2])
            cube([2, 10, box_height/2]);
        }
    }
}

// Mounting posts for the PCB
module mounting_posts() {
    positions = [
        [wall_thickness + 5, wall_thickness + 5],
        [box_width + wall_thickness - 5, wall_thickness + 5],
        [box_width + wall_thickness - 5, box_length + wall_thickness - 5],
        [wall_thickness + 5, box_length + wall_thickness - 5]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], wall_thickness])
        difference() {
            cylinder(h=5, d=post_diameter);
            cylinder(h=6, d=hole_diameter); // Screw hole
        }
    }
}

// The Lid with tolerance lip
module housing_lid() {
    union() {
        // Top plate
        rounded_block(
            box_width + wall_thickness*2, 
            box_length + wall_thickness*2, 
            wall_thickness, 
            corner_radius
        );
        
        // Inner Lip (sized down by tolerance)
        translate([wall_thickness + tolerance, wall_thickness + tolerance, -2])
        rounded_block(
            box_width - tolerance*2, 
            box_length - tolerance*2, 
            2, 
            corner_radius - wall_thickness
        );
    }
}

// --- ASSEMBLY ---

// 1. Render Body
housing_body();

// 2. Render Posts inside body
mounting_posts();

// 3. Render Lid (translated for view)
translate([0, box_length + 15, 0])
housing_lid();