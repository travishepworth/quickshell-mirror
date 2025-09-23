#!/usr/bin/env python3
"""
Rubik's Cube scramble generator with PNG visualization.
TODO: Generate the scramble properly
Requires: pip install pillow
"""

import random
from PIL import Image, ImageDraw, ImageFont
from dataclasses import dataclass
from typing import List, Dict
import copy
import os

@dataclass
class CubeState:
    """Represents the state of a Rubik's cube."""
    # Each face is a 3x3 grid (list of 9 stickers)
    U: List[str]  # Up (white)
    D: List[str]  # Down (yellow)
    F: List[str]  # Front (green)
    B: List[str]  # Back (blue)
    L: List[str]  # Left (orange)
    R: List[str]  # Right (red)

def create_solved_cube():
    """Create a solved cube state."""
    return CubeState(
        U=['W'] * 9,  # White
        D=['Y'] * 9,  # Yellow
        F=['G'] * 9,  # Green
        B=['B'] * 9,  # Blue
        L=['O'] * 9,  # Orange
        R=['R'] * 9,  # Red
    )

def generate_scramble(length=20):
    """Generate a random scramble using standard notation."""
    moves = ['R', 'L', 'U', 'D', 'F', 'B']
    modifiers = ['', "'", '2']
    
    scramble = []
    last_move = None
    
    for _ in range(length):
        # Don't repeat the same face twice in a row
        available_moves = [m for m in moves if m != last_move]
        move = random.choice(available_moves)
        modifier = random.choice(modifiers)
        scramble.append(move + modifier)
        last_move = move
    
    return ' '.join(scramble)

def rotate_face_clockwise(face):
    """Rotate a face 90 degrees clockwise."""
    # Map positions for clockwise rotation:
    # 0 1 2     6 3 0
    # 3 4 5  -> 7 4 1
    # 6 7 8     8 5 2
    new_face = face[:]
    new_face[0] = face[6]
    new_face[1] = face[3]
    new_face[2] = face[0]
    new_face[3] = face[7]
    new_face[4] = face[4]  # center stays
    new_face[5] = face[1]
    new_face[6] = face[8]
    new_face[7] = face[5]
    new_face[8] = face[2]
    return new_face

def apply_move(cube, move):
    """Apply a single move to the cube."""
    cube = copy.deepcopy(cube)
    
    if move == 'R':
        cube.R = rotate_face_clockwise(cube.R)
        # Save temp values
        temp = [cube.F[2], cube.F[5], cube.F[8]]
        # F column -> U column
        cube.F[2] = cube.D[2]
        cube.F[5] = cube.D[5]
        cube.F[8] = cube.D[8]
        # D column -> B column (opposite side, so indices flip)
        cube.D[2] = cube.B[6]
        cube.D[5] = cube.B[3]
        cube.D[8] = cube.B[0]
        # B column -> U column
        cube.B[6] = cube.U[2]
        cube.B[3] = cube.U[5]
        cube.B[0] = cube.U[8]
        # U column -> F column (temp)
        cube.U[2] = temp[0]
        cube.U[5] = temp[1]
        cube.U[8] = temp[2]
        
    elif move == "R'":
        for _ in range(3):
            cube = apply_move(cube, 'R')
            
    elif move == 'R2':
        for _ in range(2):
            cube = apply_move(cube, 'R')
            
    elif move == 'L':
        cube.L = rotate_face_clockwise(cube.L)
        # Save temp values
        temp = [cube.F[0], cube.F[3], cube.F[6]]
        # F column -> D column
        cube.F[0] = cube.U[0]
        cube.F[3] = cube.U[3]
        cube.F[6] = cube.U[6]
        # U column -> B column (opposite side, so indices flip)
        cube.U[0] = cube.B[8]
        cube.U[3] = cube.B[5]
        cube.U[6] = cube.B[2]
        # B column -> D column
        cube.B[8] = cube.D[0]
        cube.B[5] = cube.D[3]
        cube.B[2] = cube.D[6]
        # D column -> F column (temp)
        cube.D[0] = temp[0]
        cube.D[3] = temp[1]
        cube.D[6] = temp[2]
        
    elif move == "L'":
        for _ in range(3):
            cube = apply_move(cube, 'L')
            
    elif move == 'L2':
        for _ in range(2):
            cube = apply_move(cube, 'L')
            
    elif move == 'U':
        cube.U = rotate_face_clockwise(cube.U)
        # Save temp values
        temp = [cube.F[0], cube.F[1], cube.F[2]]
        # F row -> L row
        cube.F[0] = cube.R[0]
        cube.F[1] = cube.R[1]
        cube.F[2] = cube.R[2]
        # R row -> B row
        cube.R[0] = cube.B[0]
        cube.R[1] = cube.B[1]
        cube.R[2] = cube.B[2]
        # B row -> L row
        cube.B[0] = cube.L[0]
        cube.B[1] = cube.L[1]
        cube.B[2] = cube.L[2]
        # L row -> F row (temp)
        cube.L[0] = temp[0]
        cube.L[1] = temp[1]
        cube.L[2] = temp[2]
        
    elif move == "U'":
        for _ in range(3):
            cube = apply_move(cube, 'U')
            
    elif move == 'U2':
        for _ in range(2):
            cube = apply_move(cube, 'U')
            
    elif move == 'D':
        cube.D = rotate_face_clockwise(cube.D)
        # Save temp values
        temp = [cube.F[6], cube.F[7], cube.F[8]]
        # F row -> R row
        cube.F[6] = cube.L[6]
        cube.F[7] = cube.L[7]
        cube.F[8] = cube.L[8]
        # L row -> B row
        cube.L[6] = cube.B[6]
        cube.L[7] = cube.B[7]
        cube.L[8] = cube.B[8]
        # B row -> R row
        cube.B[6] = cube.R[6]
        cube.B[7] = cube.R[7]
        cube.B[8] = cube.R[8]
        # R row -> F row (temp)
        cube.R[6] = temp[0]
        cube.R[7] = temp[1]
        cube.R[8] = temp[2]
        
    elif move == "D'":
        for _ in range(3):
            cube = apply_move(cube, 'D')
            
    elif move == 'D2':
        for _ in range(2):
            cube = apply_move(cube, 'D')
            
    elif move == 'F':
        cube.F = rotate_face_clockwise(cube.F)
        # Save temp values
        temp = [cube.U[6], cube.U[7], cube.U[8]]
        # U row -> R column
        cube.U[6] = cube.L[8]
        cube.U[7] = cube.L[5]
        cube.U[8] = cube.L[2]
        # L column -> D row
        cube.L[2] = cube.D[0]
        cube.L[5] = cube.D[1]
        cube.L[8] = cube.D[2]
        # D row -> R column
        cube.D[0] = cube.R[6]
        cube.D[1] = cube.R[3]
        cube.D[2] = cube.R[0]
        # R column -> U row (temp)
        cube.R[0] = temp[0]
        cube.R[3] = temp[1]
        cube.R[6] = temp[2]
        
    elif move == "F'":
        for _ in range(3):
            cube = apply_move(cube, 'F')
            
    elif move == 'F2':
        for _ in range(2):
            cube = apply_move(cube, 'F')
            
    elif move == 'B':
        cube.B = rotate_face_clockwise(cube.B)
        # Save temp values
        temp = [cube.U[0], cube.U[1], cube.U[2]]
        # U row -> L column
        cube.U[0] = cube.R[2]
        cube.U[1] = cube.R[5]
        cube.U[2] = cube.R[8]
        # R column -> D row
        cube.R[2] = cube.D[8]
        cube.R[5] = cube.D[7]
        cube.R[8] = cube.D[6]
        # D row -> L column
        cube.D[6] = cube.L[0]
        cube.D[7] = cube.L[3]
        cube.D[8] = cube.L[6]
        # L column -> U row (temp)
        cube.L[0] = temp[2]
        cube.L[3] = temp[1]
        cube.L[6] = temp[0]
        
    elif move == "B'":
        for _ in range(3):
            cube = apply_move(cube, 'B')
            
    elif move == 'B2':
        for _ in range(2):
            cube = apply_move(cube, 'B')
    
    return cube

def apply_scramble(cube, scramble):
    """Apply a scramble sequence to the cube."""
    moves = scramble.split()
    for move in moves:
        cube = apply_move(cube, move)
    return cube

def draw_cube_net(cube, cell_size=40):
    """Draw the cube in net format as a PNG with transparent background and no gaps."""
    colors = {
        'W': (255, 255, 255),  # White
        'Y': (255, 255, 0),     # Yellow
        'G': (0, 128, 0),       # Green
        'B': (0, 0, 255),       # Blue
        'O': (255, 165, 0),     # Orange
        'R': (255, 0, 0),       # Red
    }
    
    # Create image with transparent background (12x9 grid for the net layout)
    width = cell_size * 12
    height = cell_size * 9
    img = Image.new('RGBA', (width, height), color=(0, 0, 0, 0))  # Transparent
    draw = ImageDraw.Draw(img)
    
    def draw_face(face, start_x, start_y):
        """Draw a single face at the given position with no gaps between stickers."""
        for i in range(3):
            for j in range(3):
                sticker_idx = i * 3 + j
                x = start_x + j * cell_size
                y = start_y + i * cell_size
                color = colors[face[sticker_idx]]
                
                # Draw the sticker with no margin (full cell)
                draw.rectangle(
                    [x, y, x + cell_size, y + cell_size],
                    fill=color,
                    outline=(0, 0, 0),
                    width=1
                )
    
    # Draw the net layout:
    #       U
    #     L F R B
    #       D
    
    # Up face
    draw_face(cube.U, 3 * cell_size, 0)
    
    # Middle row (L, F, R, B)
    draw_face(cube.L, 0, 3 * cell_size)
    draw_face(cube.F, 3 * cell_size, 3 * cell_size)
    draw_face(cube.R, 6 * cell_size, 3 * cell_size)
    draw_face(cube.B, 9 * cell_size, 3 * cell_size)
    
    # Down face
    draw_face(cube.D, 3 * cell_size, 6 * cell_size)
    
    return img

def main():
    """Generate scramble and save cube visualization."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Generate scramble
    scramble = generate_scramble()
    print(f"Scramble: {scramble}")
    
    # Create and scramble cube
    cube = create_solved_cube()
    scrambled_cube = apply_scramble(cube, scramble)
    
    # Generate and save image as PNG with transparency
    img = draw_cube_net(scrambled_cube)
    img.save('../assets/cube/scramble.png', 'PNG')
    print("Cube visualization saved as 'scramble.png'")
    
    # Also save scramble to text file for reference
    with open('../assets/cube/scramble.txt', 'w') as f:
        f.write(scramble)
    print("Scramble text saved as 'scramble.txt'")

if __name__ == "__main__":
    main()
