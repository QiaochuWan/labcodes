import tkinter as tk  # Import the tkinter library for GUI components
from tkinter import filedialog  # Import filedialog for file selection dialog
from PIL import Image, ImageTk  # Import Pillow for image handling
import numpy as np  # Import numpy for numerical operations

class ImageApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image Processing GUI")  # Set the window title
        
        # Frame to hold the control buttons and labels
        control_frame = tk.Frame(root)
        control_frame.pack(side=tk.RIGHT, fill=tk.Y)  # Pack the frame to the right side
        
        # Button to load an image
        self.btn_load = tk.Button(control_frame, text="Load Image", command=self.load_image)
        self.btn_load.pack()  # Pack the button
        
        # Button to enable drawing mode
        self.btn_draw = tk.Button(control_frame, text="Enable Drawing", command=self.enable_drawing)
        self.btn_draw.pack()  # Pack the button
        
        # Button to clear drawings
        self.btn_clear = tk.Button(control_frame, text="Clear Drawings", command=self.clear_drawings)
        self.btn_clear.pack()  # Pack the button
        
        # StringVar to hold the RGB values and contrast text
        self.rgb_values = tk.StringVar()
        self.rgb_values.set("Average RGB Values and Contrast:")  # Initialize the text
        self.label = tk.Label(control_frame, textvariable=self.rgb_values)
        self.label.pack()  # Pack the label

        # StringVars to hold the individual R, G, B values
        self.r_value = tk.StringVar()
        self.g_value = tk.StringVar()
        self.b_value = tk.StringVar()

        # Labels to display the individual R, G, B values
        self.r_label = tk.Label(control_frame, textvariable=self.r_value)
        self.r_label.pack()  # Pack the R value label
        
        self.g_label = tk.Label(control_frame, textvariable=self.g_value)
        self.g_label.pack()  # Pack the G value label
        
        self.b_label = tk.Label(control_frame, textvariable=self.b_value)
        self.b_label.pack()  # Pack the B value label
        
        # Variables to store line coordinates and drawing state
        self.line_coords = []  # List to store coordinates of the lines
        self.image = None  # Variable to store the loaded image
        self.photo = None  # Variable to store the PhotoImage
        self.lines = []  # List to store line IDs
        
        self.drawing_enabled = False  # Flag to check if drawing is enabled
        self.drawing_active = False  # Flag to check if drawing is active

        # Create a canvas to display the image with fixed size
        self.canvas = tk.Canvas(root, width=1280, height=960)
        self.canvas.pack(side=tk.LEFT)  # Pack the canvas to the left side

    def load_image(self):
        """Load an image and display it on the canvas."""
        file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png")])
        if file_path:
            self.image = Image.open(file_path).convert('RGB')  # Open and convert image to RGB
            self.image.thumbnail((1280, 960))  # Resize image to fit within 256x192 while maintaining aspect ratio
            self.photo = ImageTk.PhotoImage(self.image)  # Convert image to PhotoImage
            self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW)  # Display image on canvas
            self.canvas.config(scrollregion=self.canvas.bbox(tk.ALL))  # Configure scroll region

    def enable_drawing(self):
        """Enable drawing mode."""
        self.drawing_enabled = True  # Set drawing_enabled flag to True
        self.canvas.bind("<ButtonPress-1>", self.start_line)  # Bind mouse button press event
        self.canvas.bind("<B1-Motion>", self.draw_line)  # Bind mouse motion event
        self.canvas.bind("<ButtonRelease-1>", self.end_line)  # Bind mouse button release event

    def start_line(self, event):
        """Start a new line when the mouse button is pressed."""
        if self.drawing_enabled:
            self.drawing_active = True  # Set drawing_active flag to True
            self.current_line_start = (event.x, event.y)  # Store the starting coordinates of the line
            self.current_line_id = None  # Initialize current_line_id to None

    def draw_line(self, event):
        """Draw a line as the mouse moves."""
        if self.drawing_active:
            if self.current_line_id:
                self.canvas.delete(self.current_line_id)  # Delete the previous line segment
            # Draw the new line segment
            self.current_line_id = self.canvas.create_line(self.current_line_start, (event.x, event.y), fill="red" if len(self.line_coords) % 2 == 0 else "blue")

    def end_line(self, event):
        """Finish drawing the line when the mouse button is released."""
        if self.drawing_active:
            self.drawing_active = False  # Set drawing_active flag to False
            # Store the line coordinates
            self.line_coords.append([self.current_line_start, (event.x, event.y)])
            self.lines.append(self.current_line_id)  # Store the line ID
            self.current_line_id = None  # Reset current_line_id to None
            if len(self.line_coords) == 2:
                self.calculate_rgb_and_contrast()  # Calculate RGB values and contrast if two lines are drawn

    def clear_drawings(self):
        """Clear all drawings from the canvas."""
        for line_id in self.lines:
            self.canvas.delete(line_id)  # Delete each line from the canvas
        self.lines = []  # Clear the lines list
        self.line_coords = []  # Clear the line coordinates list
        self.rgb_values.set("Average RGB Values and Contrast:")  # Reset the RGB values text
        self.r_value.set("")  # Clear R value
        self.g_value.set("")  # Clear G value
        self.b_value.set("")  # Clear B value
        self.drawing_enabled = False  # Set drawing_enabled flag to False

    def calculate_rgb_and_contrast(self):
        """Calculate and display the average RGB values and contrast for the drawn lines."""
        img_array = np.array(self.image)  # Convert image to numpy array
        if len(self.line_coords) < 2:
            return  # Return if less than two lines are drawn
        
        line1_rgb = self.get_line_rgb(self.line_coords[0], img_array)  # Get RGB values for the first line
        line2_rgb = self.get_line_rgb(self.line_coords[1], img_array)  # Get RGB values for the second line
        
        # Calculate contrast between the two lines for each RGB channel
        contrast = [abs(line2_rgb[i] - line1_rgb[i]) / line1_rgb[i] for i in range(3)]
        # Set the result text
        result_text = (f"Average RGB Line 1 (background): {line1_rgb}\n"
                       f"Average RGB Line 2 (sample): {line2_rgb}\n"
                       f"Contrast: {contrast}")
        self.rgb_values.set(result_text)  # Update the RGB values and contrast text
        
        # Update the individual R, G, B values
        self.r_value.set(f"R values: Line 1 - {line1_rgb[0]}, Line 2 - {line2_rgb[0]}, Contrast - {contrast[0]:.2f}")
        self.g_value.set(f"G values: Line 1 - {line1_rgb[1]}, Line 2 - {line2_rgb[1]}, Contrast - {contrast[1]:.2f}")
        self.b_value.set(f"B values: Line 1 - {line1_rgb[2]}, Line 2 - {line2_rgb[2]}, Contrast - {contrast[2]:.2f}")

    def get_line_rgb(self, line_coords, img_array):
        """Get the average RGB values along a line."""
        # Generate x and y values along the line
        x_values = np.linspace(line_coords[0][0], line_coords[1][0], num=1000).astype(int)
        y_values = np.linspace(line_coords[0][1], line_coords[1][1], num=1000).astype(int)
        rgb_values = img_array[y_values, x_values]  # Get RGB values from the image array
        avg_rgb = np.mean(rgb_values, axis=0).astype(int)  # Calculate the average RGB values
        return avg_rgb  # Return the average RGB values

if __name__ == "__main__":
    root = tk.Tk()  # Create the main window
    app = ImageApp(root)  # Create an instance of the ImageApp class
    root.mainloop()  # Run the main event loop
