import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk, ImageOps
import numpy as np

class ImageApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image Processing GUI")
        
        # Frame to hold the control buttons and labels
        control_frame = tk.Frame(root)
        control_frame.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Button to load an image
        self.btn_load = tk.Button(control_frame, text="Load Image", command=self.load_image)
        self.btn_load.pack()
        
        # Button to enable drawing mode
        self.btn_draw = tk.Button(control_frame, text="Enable Drawing", command=self.enable_drawing)
        self.btn_draw.pack()
        
        # Button to clear drawings
        self.btn_clear = tk.Button(control_frame, text="Clear Drawings", command=self.clear_drawings)
        self.btn_clear.pack()
        
        # Entry and button for pixel-to-micrometer ratio
        self.ratio_label = tk.Label(control_frame, text="Pixel to Micrometer Ratio:")
        self.ratio_label.pack()
        self.ratio_entry = tk.Entry(control_frame)
        self.ratio_entry.pack()
        self.ratio_button = tk.Button(control_frame, text="Confirm Ratio", command=self.confirm_ratio)
        self.ratio_button.pack()

        # StringVar to hold the RGB values and contrast text
        self.rgb_values = tk.StringVar()
        self.rgb_values.set("Average RGB Values and Contrast:")
        self.label = tk.Label(control_frame, textvariable=self.rgb_values)
        self.label.pack()

        # StringVars to hold the individual R, G, B values
        self.r_value = tk.StringVar()
        self.g_value = tk.StringVar()
        self.b_value = tk.StringVar()

        # Labels to display the individual R, G, B values
        self.r_label = tk.Label(control_frame, textvariable=self.r_value)
        self.r_label.pack()
        
        self.g_label = tk.Label(control_frame, textvariable=self.g_value)
        self.g_label.pack()
        
        self.b_label = tk.Label(control_frame, textvariable=self.b_value)
        self.b_label.pack()
        
        # Variables to store line coordinates and drawing state
        self.line_coords = []
        self.original_line_coords = []
        self.image = None
        self.photo = None
        self.lines = []
        self.line_labels = []
        
        self.drawing_enabled = False
        self.drawing_active = False
        self.pixel_to_micrometer_ratio = 1.0  # Default ratio

        # Create a canvas to display the image with fixed size
        self.canvas = tk.Canvas(root, width=1280, height=960)
        self.canvas.pack(side=tk.LEFT)

        # Variables for image movement
        self.image_id = None
        self.start_x = 0
        self.start_y = 0
        self.current_scale = 1.0  # Initial scale of the image

        # Bind right-click and mouse wheel events for moving and zooming the image
        self.canvas.bind("<ButtonPress-3>", self.start_move)
        self.canvas.bind("<B3-Motion>", self.move_image)
        self.canvas.bind("<MouseWheel>", self.zoom_image)

    def load_image(self):
        """Load an image and display it on the canvas."""
        file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png")])
        if file_path:
            self.image = Image.open(file_path).convert('RGB')  # Open and convert image to RGB
            self.image.thumbnail((1280, 960), Image.Resampling.LANCZOS)  # Resize image to fit within 1280x960 while maintaining aspect ratio
            self.photo = ImageTk.PhotoImage(self.image)  # Convert image to PhotoImage
            if self.image_id:
                self.canvas.delete(self.image_id)
            self.image_id = self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW, tags="image")  # Display image on canvas
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
            self.current_line_start = (event.x / self.current_scale, event.y / self.current_scale)  # Store the starting coordinates of the line
            self.current_line_id = None  # Initialize current_line_id to None

    def draw_line(self, event):
        """Draw a line as the mouse moves."""
        if self.drawing_active:
            scaled_start = (self.current_line_start[0] * self.current_scale, self.current_line_start[1] * self.current_scale)
            current_coords = (event.x, event.y)
            if self.current_line_id:
                self.canvas.delete(self.current_line_id)  # Delete the previous line segment
            # Draw the new line segment
            self.current_line_id = self.canvas.create_line(scaled_start, current_coords, fill="red" if len(self.line_coords) % 2 == 0 else "blue", tags="line")

    def end_line(self, event):
        """Finish drawing the line when the mouse button is released."""
        if self.drawing_active:
            self.drawing_active = False  # Set drawing_active flag to False
            end_coords = (event.x / self.current_scale, event.y / self.current_scale)
            # Store the line coordinates
            self.line_coords.append([self.current_line_start, end_coords])
            self.original_line_coords.append([self.current_line_start, end_coords])
            self.lines.append(self.current_line_id)  # Store the line ID
            # Calculate the length of the line
            line_length = np.sqrt((end_coords[0] - self.current_line_start[0]) ** 2 + 
                                  (end_coords[1] - self.current_line_start[1]) ** 2)
            micrometer_length = line_length / self.pixel_to_micrometer_ratio
            # Add a text label showing the line number and length
            line_number = len(self.line_coords)
            scaled_start = (self.current_line_start[0] * self.current_scale, self.current_line_start[1] * self.current_scale)
            scaled_end = (end_coords[0] * self.current_scale, end_coords[1] * self.current_scale)
            label_id = self.canvas.create_text((scaled_start[0] + scaled_end[0]) // 2,
                                               (scaled_start[1] + scaled_end[1]) // 2,
                                               text=f"{line_number}: {micrometer_length:.2f} {'μm' if self.pixel_to_micrometer_ratio != 1 else 'px'}", fill="black", tags="label")
            self.line_labels.append(label_id)
            self.current_line_id = None  # Reset current_line_id to None
            if len(self.line_coords) == 2:
                self.calculate_rgb_and_contrast()  # Calculate RGB values and contrast if two lines are drawn

    def clear_drawings(self):
        """Clear all drawings from the canvas."""
        for line_id in self.lines:
            self.canvas.delete(line_id)  # Delete each line from the canvas
        for label_id in self.line_labels:
            self.canvas.delete(label_id)  # Delete each label from the canvas
        self.lines = []  # Clear the lines list
        self.line_labels = []  # Clear the labels list
        self.line_coords = []  # Clear the line coordinates list
        self.original_line_coords = []  # Clear the original line coordinates list
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

    def start_move(self, event):
        """Start moving the image when the right mouse button is pressed."""
        self.start_x = event.x
        self.start_y = event.y

    def move_image(self, event):
        """Move the image on the canvas."""
        dx = event.x - self.start_x
        dy = event.y - self.start_y
        self.canvas.move(self.image_id, dx, dy)
        for line_id in self.lines:
            self.canvas.move(line_id, dx, dy)
        for label_id in self.line_labels:
            self.canvas.move(label_id, dx, dy)
        self.start_x = event.x
        self.start_y = event.y

    def zoom_image(self, event):
        """Zoom the image in or out with the mouse wheel."""
        if event.delta > 0:  # Zoom in
            self.current_scale *= 1.1
        elif event.delta < 0:  # Zoom out
            self.current_scale /= 1.1

        # Resize the image
        new_size = (int(self.image.width * self.current_scale), int(self.image.height * self.current_scale))
        resized_image = self.image.resize(new_size, Image.Resampling.LANCZOS)
        self.photo = ImageTk.PhotoImage(resized_image)

        # Redraw the image on the canvas
        if self.image_id:
            self.canvas.delete(self.image_id)
        self.image_id = self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW, tags="image")
        self.canvas.config(scrollregion=self.canvas.bbox(tk.ALL))

        # Move and scale lines and labels
        for i, (start, end) in enumerate(self.original_line_coords):
            if self.lines[i] is not None:
                scaled_start = (start[0] * self.current_scale, start[1] * self.current_scale)
                scaled_end = (end[0] * self.current_scale, end[1] * self.current_scale)
                self.canvas.coords(self.lines[i], scaled_start[0], scaled_start[1], scaled_end[0], scaled_end[1])
                line_length = np.sqrt((end[0] - start[0]) ** 2 + (end[1] - start[1]) ** 2)
                micrometer_length = line_length / self.pixel_to_micrometer_ratio
                self.canvas.coords(self.line_labels[i],
                                   (scaled_start[0] + scaled_end[0]) // 2,
                                   (scaled_start[1] + scaled_end[1]) // 2)
                self.canvas.itemconfig(self.line_labels[i], text=f"{i + 1}: {micrometer_length:.2f} {'μm' if self.pixel_to_micrometer_ratio != 1 else 'px'}")

        # Bring lines and labels to the front
        self.canvas.tag_raise("line")
        self.canvas.tag_raise("label")

    def confirm_ratio(self):
        """Confirm the pixel-to-micrometer ratio and update the lengths of lines."""
        try:
            ratio = float(self.ratio_entry.get())
            if ratio > 0:
                self.pixel_to_micrometer_ratio = ratio
            else:
                self.pixel_to_micrometer_ratio = 1.0
        except ValueError:
            self.pixel_to_micrometer_ratio = 1.0
        
        # Update the lengths of existing lines
        for i, (start, end) in enumerate(self.original_line_coords):
            line_length = np.sqrt((end[0] - start[0]) ** 2 + (end[1] - start[1]) ** 2)
            micrometer_length = line_length / self.pixel_to_micrometer_ratio
            self.canvas.itemconfig(self.line_labels[i], text=f"{i + 1}: {micrometer_length:.2f} {'μm' if self.pixel_to_micrometer_ratio != 1 else 'px'}")

if __name__ == "__main__":
    root = tk.Tk()  # Create the main window
    app = ImageApp(root)  # Create an instance of the ImageApp class
    root.mainloop()  # Run the main event loop
