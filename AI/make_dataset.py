import cv2
import os

def extract_frames_from_videos(video_folder, output_folder):
    # 비디오 폴더 내 모든 파일 목록 가져오기
    video_files = [f for f in os.listdir(video_folder) if f.endswith('.mp4')]
    
    # 출력 폴더 생성
    os.makedirs(output_folder, exist_ok=True)
    
    for video_file in video_files:
        video_path = os.path.join(video_folder, video_file)
        cap = cv2.VideoCapture(video_path)
        
        frame_count = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # 초당 1프레임 추출
            if frame_count % 30 == 0:
                frame_filename = os.path.join(output_folder, f"{os.path.splitext(video_file)[0]}_frame_{frame_count}.jpg")
                cv2.imwrite(frame_filename, frame)
            
            frame_count += 1
        
        cap.release()
        print(f"{video_file}에서 총 {frame_count // 30}개 프레임 추출 완료")

# 사용 예시
video_folder_path = "./videos"  # MP4 파일들이 담긴 폴더 경로
frame_output_path = "./frames"  # 프레임을 저장할 폴더 경로

extract_frames_from_videos(video_folder_path, frame_output_path)