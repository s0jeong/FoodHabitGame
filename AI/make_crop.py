import cv2
import os

def extract_face_region(image, face_cascade):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)
    
    for (x, y, w, h) in faces:
        # 얼굴 전체 영역을 추출
        face_region = image[y:y+h, x:x+w]
        return cv2.resize(face_region, (64, 64))  # 크기 조정
    
    return None

def process_dataset(input_dir, output_dir):
    face_cascade_path = './haarcascade_frontalface_default.xml'
    face_cascade = cv2.CascadeClassifier(face_cascade_path)
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for filename in os.listdir(input_dir):
        if filename.endswith(('.png', '.jpg', '.jpeg')):
            image_path = os.path.join(input_dir, filename)
            image = cv2.imread(image_path)
            
            face_region = extract_face_region(image, face_cascade)
            
            if face_region is not None:
                output_path = os.path.join(output_dir, filename)
                cv2.imwrite(output_path, face_region)
                print(f"Processed: {filename}")
            else:
                print(f"No face detected in: {filename}")


# 사용 예시
input_directory = './labeled'
output_directory = './labeled_crop'
process_dataset(input_directory, output_directory)