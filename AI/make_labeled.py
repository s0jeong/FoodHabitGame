import os
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk

class ImageLabeler:
    def __init__(self, master):
        self.master = master
        self.master.title("Image Labeler")
        self.image_folder = "videos"
        self.current_image_index = 0
        self.images = []
        self.labeled_folder = "labeled"
        os.makedirs(self.labeled_folder, exist_ok=True)

        self.setup_ui()

    def setup_ui(self):
        self.image_label = tk.Label(self.master)
        self.image_label.pack()

        self.eating_button = tk.Button(self.master, text="먹는 중 (1)", command=lambda: self.label_image(1))
        self.eating_button.pack(side=tk.LEFT, padx=10)

        self.not_eating_button = tk.Button(self.master, text="먹지 않음 (0)", command=lambda: self.label_image(0))
        self.not_eating_button.pack(side=tk.LEFT, padx=10)

        self.load_folder_button = tk.Button(self.master, text="폴더 불러오기", command=self.load_folder)
        self.load_folder_button.pack(side=tk.LEFT, padx=10)

    def load_folder(self):
        self.image_folder = filedialog.askdirectory()
        self.images = [f for f in os.listdir(self.image_folder) if f.endswith(('.png', '.jpg', '.jpeg'))]
        self.current_image_index = 0
        self.show_image()

    def show_image(self):
        if self.current_image_index < len(self.images):
            image_path = os.path.join(self.image_folder, self.images[self.current_image_index])
            image = Image.open(image_path)
            image = image.resize((400, 400), Image.LANCZOS)
            photo = ImageTk.PhotoImage(image)
            self.image_label.config(image=photo)
            self.image_label.image = photo
            self.master.title(f"Image Labeler - {self.images[self.current_image_index]}")

    def label_image(self, label):
        if self.current_image_index < len(self.images):
            image_name = f"{self.current_image_index}_{label}.png"
            labeled_path = os.path.join(self.labeled_folder, image_name)

            # 원본 이미지 경로
            original_image_path = os.path.join(self.image_folder, self.images[self.current_image_index])
            
            # 원본 이미지를 라벨링된 폴더에 저장
            image = Image.open(original_image_path)
            image.save(labeled_path)

            print(f"Saved: {labeled_path}")

            # 다음 이미지로 이동
            self.current_image_index += 1
            self.show_image()

root = tk.Tk()
app = ImageLabeler(root)
root.mainloop()