import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader

# 데이터 전처리 설정
data_transforms = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

# 데이터셋 로드
data_dir = './labeled_crop'  # 이미지가 저장된 디렉토리
train_dataset = datasets.ImageFolder(root=data_dir, transform=data_transforms)
train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)

# 사전 학습된 ResNet-18 모델 로드
model = models.resnet18(pretrained=True)

# 마지막 레이어 교체 (이진 분류를 위해)
num_features = model.fc.in_features
model.fc = nn.Linear(num_features, 1)  # 출력 노드 수를 1로 설정

# 손실 함수 및 옵티마이저 설정
criterion = nn.BCEWithLogitsLoss()  # 이진 분류에 적합한 손실 함수
optimizer = optim.Adam(model.parameters(), lr=0.001)

# 장치 설정 (GPU 사용 가능 시)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# 학습 루프
num_epochs = 10  # 에포크 수 설정

for epoch in range(num_epochs):
    model.train()  # 학습 모드로 변경
    running_loss = 0.0
    
    for inputs, labels in train_loader:
        inputs, labels = inputs.to(device), labels.to(device).float()
        
        optimizer.zero_grad()  # 기울기 초기화
        
        # 순전파 및 손실 계산
        outputs = model(inputs)
        loss = criterion(outputs.view(-1), labels)
        
        # 역전파 및 옵티마이저 스텝
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
    
    print(f'Epoch [{epoch+1}/{num_epochs}], Loss: {running_loss/len(train_loader):.4f}')

# 모델 저장
torch.save(model.state_dict(), 'eating_detection_resnet18.pth')