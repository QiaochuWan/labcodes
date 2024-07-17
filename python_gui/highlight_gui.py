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
        
        # Button to enable pixel selection mode
        self.btn_select_pixel = tk.Button(control_frame, text="Select Pixel", command=self.enable_pixel_selection)
        self.btn_select_pixel.pack()
        
        # Checkbutton to enable image movement
        self.movement_enabled = tk.BooleanVar()
        self.click_move = tk.Checkbutton(control_frame, text='Click to Move', variable=self.movement_enabled)
        self.click_move.pack(side='bottom')

        # StringVar to hold the RGB values and contrast text
        self.rgb_values = tk.StringVar()
        # self.rgb_values.set("Average RGB Values and Contrast:")
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

        # Variables for pixel selection
        self.pixel_selection_enabled = False
        self.selected_pixel = None
        self.tolerance = 1 # Tolerance for RGB value similarity

        # Variables for selection range
        self.selection_start = None
        self.selection_rect = None

        # Tolerance input
        self.tolerance_label = tk.Label(control_frame, text="Tolerance:")
        self.tolerance_label.pack()

        self.tolerance_entry = tk.Entry(control_frame)
        self.tolerance_entry.pack()
        self.tolerance_entry.insert(1, str(self.tolerance))  # Set the default value

        self.btn_set_tolerance = tk.Button(control_frame, text="Set Tolerance", command=self.set_tolerance)
        self.btn_set_tolerance.pack()

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

    def enable_pixel_selection(self):
        """Enable pixel selection mode."""
        self.pixel_selection_enabled = True  # Enable pixel selection mode
        self.drawing_enabled = False  # Disable drawing mode
        self.canvas.bind("<ButtonPress-1>", self.start_selection)  # Bind mouse click event to start selection
        self.canvas.bind("<B1-Motion>", self.update_selection)  # Bind mouse motion event to update selection
        self.canvas.bind("<ButtonRelease-1>", self.end_selection)  # Bind mouse release event to end selection

    def start_selection(self, event):
        """Start the selection of a pixel range."""
        if self.pixel_selection_enabled:
            self.selection_start = (int(event.x / self.current_scale), int(event.y / self.current_scale))
            if self.selection_rect:
                self.canvas.delete(self.selection_rect)
            self.selection_rect = self.canvas.create_rectangle(event.x, event.y, event.x, event.y, outline='red')

    def update_selection(self, event):
        """Update the selection rectangle as the mouse moves."""
        if self.pixel_selection_enabled and self.selection_start:
            self.canvas.coords(self.selection_rect, self.selection_start[0] * self.current_scale,
                               self.selection_start[1] * self.current_scale, event.x, event.y)

    def end_selection(self, event):
        """End the selection and highlight similar pixels."""
        if self.pixel_selection_enabled and self.selection_start:
            end_x, end_y = int(event.x / self.current_scale), int(event.y / self.current_scale)
            img_array = np.array(self.image)  # Convert image to numpy array
            start_x, start_y = self.selection_start
            selected_area = img_array[start_y:end_y, start_x:end_x]  # Get the selected area
            self.selected_pixel = np.mean(selected_area, axis=(0, 1)).astype(int)  # Calculate average RGB
            self.highlight_similar_pixels(img_array, self.selected_pixel)
            self.selection_start = None
            self.canvas.delete(self.selection_rect)

    def highlight_similar_pixels(self, img_array, selected_pixel):
        """Highlight pixels with similar RGB values to the selected pixel."""
        tolerance = self.tolerance
        mask = np.all(np.abs(img_array - selected_pixel) <= tolerance, axis=-1)  # Create a mask for similar pixels
        img_highlighted = img_array.copy()
        img_highlighted[mask] = [164, 237, 207]  # Highlight similar pixels in green
        highlighted_image = Image.fromarray(img_highlighted)
        self.photo = ImageTk.PhotoImage(highlighted_image)
        self.canvas.delete(self.image_id)
        self.image_id = self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW, tags="image")

    def start_move(self, event):
        """Start moving the image when the right mouse button is pressed."""
        self.start_x = event.x
        self.start_y = event.y

    def move_image(self, event):
        """Move the image on the canvas."""
        if self.movement_enabled.get():
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
        if self.movement_enabled.get():
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


    def set_tolerance(self):
        """Set the tolerance value from the input field and refresh the highlight."""
        try:
            self.tolerance = int(self.tolerance_entry.get())
            if self.selected_pixel is not None:
                img_array = np.array(self.image)  # Convert image to numpy array
                self.highlight_similar_pixels(img_array, self.selected_pixel)  # Refresh highlight
        except ValueError:
            pass  # Handle invalid input if necessary
if __name__ == "__main__":
    root = tk.Tk()  # Create the main window
    app = ImageApp(root)  # Create an instance of the ImageApp class
    root.mainloop()  # Run the main event loop
