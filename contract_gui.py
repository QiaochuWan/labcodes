import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
import numpy as np

class ImageApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image contract GUI")
        self.canvas = tk.Canvas(root, width=800, height=600)
        self.canvas.pack()
        
        self.btn_load = tk.Button(root, text="Load Image", command=self.load_image)
        self.btn_load.pack()
        
        self.btn_draw = tk.Button(root, text="Draw Lines", command=self.enable_drawing)
        self.btn_draw.pack()
        
        self.line_coords = []
        self.image = None
        self.photo = None
        self.lines = []
        
        self.canvas.bind("<Button-1>", self.on_click)
        
        self.rgb_values = tk.StringVar()
        self.rgb_values.set("Average RGB Values and Contrast:")
        self.label = tk.Label(root, textvariable=self.rgb_values)
        self.label.pack()
        
        self.drawing_enabled = False

    def load_image(self):
        file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png")])
        if file_path:
            self.image = Image.open(file_path)
            self.photo = ImageTk.PhotoImage(self.image)
            self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW)
            self.canvas.config(scrollregion=self.canvas.bbox(tk.ALL))

    def enable_drawing(self):
        self.drawing_enabled = True

    def on_click(self, event):
        if self.drawing_enabled:
            self.draw_line(event)

    def draw_line(self, event):
        if len(self.line_coords) < 4:
            self.line_coords.append((event.x, event.y))
            if len(self.line_coords) == 4:
                line1 = self.canvas.create_line(self.line_coords[0], self.line_coords[1], fill="red")
                line2 = self.canvas.create_line(self.line_coords[2], self.line_coords[3], fill="blue")
                self.lines.append(line1)
                self.lines.append(line2)
                self.calculate_rgb_and_contrast()
        else:
            for line in self.lines:
                self.canvas.delete(line)
            self.lines = []
            self.line_coords = [(event.x, event.y)]

    def calculate_rgb_and_contrast(self):
        img_array = np.array(self.image)
        print(np.shape(img_array))
        line1_rgb = self.get_line_rgb(self.line_coords[0], self.line_coords[1], img_array)
        line2_rgb = self.get_line_rgb(self.line_coords[2], self.line_coords[3], img_array)
       # print(np.size(line1_rgb))
        contrast = [abs(line2_rgb[i] - line1_rgb[i])/ line1_rgb[i] for i in range(3)]
        result_text = (f"Average RGB Line 1 background: {line1_rgb}\n"
                       f"Average RGB Line 2 sample: {line2_rgb}\n"
                       f"Contrast: {contrast}")
        self.rgb_values.set(result_text)

    def get_line_rgb(self, start, end, img_array):
        x0, y0 = start
        x1, y1 = end
        length = max(abs(x1 - x0), abs(y1 - y0))
        x_values = np.linspace(x0, x1, length).astype(int)
        y_values = np.linspace(y0, y1, length).astype(int)
        rgb_values = img_array[y_values, x_values]
       # print(rgb_values)
        avg_rgb = np.mean(rgb_values, axis=0).astype(int)
        return avg_rgb

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageApp(root)
    root.mainloop()
