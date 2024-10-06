from Tkinter import *
import Image, ImageTk
from tkinter import filedialog
root = Tk()
root.geometry('1000x1000')
canvas = Canvas(root,width=999,height=999)
canvas.pack()
file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png")])
pilImage = Image.open(file_path)
image = ImageTk.PhotoImage(pilImage)
imagesprite = canvas.create_image(400,400,image=image)
root.mainloop()
