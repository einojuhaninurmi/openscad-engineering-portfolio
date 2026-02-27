/* 
   PROJECT: Procedural Radial Heatsink Generator
   DESCRIPTION: 
   Generates a radial fin pattern using trigonometric distribution.
   Showcases math-based parametric design and Boolean intersections.
*/

// --- PARAMETERS ---
base_diameter  = 60;
core_diameter  = 15;
height         = 40;
num_fins       = 36;   // Number of fins around the core
fin_thickness  = 2;
twist_angle    = 30;   // Twist of fins from bottom to top (Helix effect)

// --- MAIN GEOMETRY ---

difference() {
    // UNION of all positive shapes
    union() {
        // 1. Solid Center Core
        cylinder(h = height, d = core_diameter, $fn=50);
        
        // 2. Fin Generation Loop
        for (i = [0 : num_fins - 1]) {
            // Calculate rotation angle per fin
            angle = i * (360 / num_fins);
            
            rotate([0, 0, angle])
            linear_extrude(height = height, twist = twist_angle, slices = 50)
            translate([core_diameter/2 - 1, -fin_thickness/2, 0])
            square([base_diameter/2 - core_diameter/2 + 1, fin_thickness]);
        }
    }

    // --- SUBTRACTIVE GEOMETRY (The CSG approach) ---
    // Cut out a cone from the top to increase surface area/airflow
    translate([0, 0, height])
    cylinder(h = height/2, d1 = base_diameter * 0.8, d2 = 0, center = true, $fn=50);
    
    // Mounting hole through center
    cylinder(h = height * 3, d = 4, center=true, $fn=20);
}
