/* 
   PROJECT: Algorithmic Sweep Generator (Trefoil Knot)
   
   DESCRIPTION: 
   OpenSCAD lacks a native sweep function.
   This script implements a custom sweep engine using:
   1. Parametric path generation (Trefoil Knot).
   2. Frenet-Serret frame approximation (Tangent/Normal vectors).
   3. 4x4 Matrix transformations applied to raw vertex data.
   4. Topology stitching via 'polyhedron()'.
*/

// --- CONFIGURATION ---
step_count = 150;     // Resolution of the path
profile_sides = 6;    // Hexagonal cross-section
path_scale = 30;      // Size of the knot
tube_radius = 6;      // Thickness of the tube
twist_factor = 3;     // Artificial twist along the path

// --- MATHEMATICAL FUNCTIONS ---

// 1. Parametric Function for Trefoil Knot (returns [x,y,z])
function trefoil(t) = 
    [
        sin(t) + 2 * sin(2 * t),
        cos(t) - 2 * cos(2 * t),
        -sin(3 * t)
    ] * path_scale;

// 2. 2D Profile Generator (returns list of [x,y] points)
function get_profile_points(r, sides) = 
    [ for (i = [0 : sides-1]) 
        [ r * cos(i * 360 / sides), r * sin(i * 360 / sides), 0 ] 
    ];

// 3. Matrix Math: Create a transformation matrix
// Maps the profile to the current point on the curve, aligning with tangent
function rotation_matrix(dir, up=[0,0,1]) = 
    let(
        z = dir / norm(dir),      // Tangent vector
        x = cross(up, z) / norm(cross(up, z)), // Normal vector
        y = cross(z, x)           // Binormal vector
    )
    [
        [x[0], y[0], z[0], 0],
        [x[1], y[1], z[1], 0],
        [x[2], y[2], z[2], 0],
        [0,    0,    0,    1]
    ];

// 4. Matrix Math: Apply matrix to a point
function transform_point(m, p) = 
    [
        m[0][0]*p[0] + m[0][1]*p[1] + m[0][2]*p[2] + m[0][3],
        m[1][0]*p[0] + m[1][1]*p[1] + m[1][2]*p[2] + m[1][3],
        m[2][0]*p[0] + m[2][1]*p[1] + m[2][2]*p[2] + m[2][3]
    ];

// --- MESH GENERATION LOGIC ---

// Generate the backbone path points
path_points = [ for (i = [0 : step_count]) trefoil(i * 360 / step_count) ];

// Generate the base profile
raw_profile = get_profile_points(tube_radius, profile_sides);

// CALCULATE VERTICES (The hard part)
// Iterate through path, calculate tangent, create matrix, transform profile
all_vertices = [
    for (i = [0 : step_count-1]) 
        let(
            p_curr = path_points[i],
            p_next = path_points[(i+1) % step_count],
            
            // Calculate tangent vector
            tangent = p_next - p_curr,
            
            // Generate rotation matrix based on tangent
            rot_mat = rotation_matrix(tangent),
            
            // Add twist rotation (optional aesthetic)
            twist_rot = i * twist_factor
        )
        for (pt = raw_profile)
            // Apply twist -> Apply orientation -> Move to position
            p_curr + transform_point(rot_mat, 
                [pt[0]*cos(twist_rot) - pt[1]*sin(twist_rot), 
                 pt[0]*sin(twist_rot) + pt[1]*cos(twist_rot), 
                 0]
            )
];

// CALCULATE FACES (Stitching the vertices together)
// Connects ring 'i' to ring 'i+1' with triangles
faces = [
    for (i = [0 : step_count-1])
        for (j = [0 : profile_sides-1])
            let(
                current_ring_start = i * profile_sides,
                next_ring_start = ((i + 1) % step_count) * profile_sides,
                next_j = (j + 1) % profile_sides
            )
            [
                current_ring_start + j,
                next_ring_start + j,
                next_ring_start + next_j,
                current_ring_start + next_j
            ] // Creates a quad (OpenSCAD splits to triangles auto)
];

// --- RENDER ---

// The final output is a single, mathematically pure object
color("DeepSkyBlue")
polyhedron(points = all_vertices, faces = faces);