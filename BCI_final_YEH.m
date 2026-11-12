close all;
clear;
sca;
clc;

KbName('UnifyKeyNames');
spaceKey = KbName('space');
escKey   = KbName('ESCAPE');

Screen('Preference','SkipSyncTests',1);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
[window, rect] = Screen('OpenWindow', screenNumber, [0 0 0]);
[xCenter, yCenter] = RectCenter(rect);

%--- 1. 開始畫面 ---
Screen('TextSize', window, 125);
DrawFormattedText(window, 'Press any key to start', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

%--- 2. 倒數計時 ---
Screen('TextSize', window, 150);
for countdown = 3:-1:1
    Screen('FillRect', window, [0 0 0]);
    DrawFormattedText(window, num2str(countdown), 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(1);
end

%--- 3. 注視點 (Fixation Cross) ---
Screen('FillRect', window, [0 0 0]);
Screen('TextSize', window, 500);
DrawFormattedText(window, '+', 'center', yCenter + 175, white);
Screen('Flip', window);
WaitSecs(0.5);

%--- 4. 數獨棋盤資料初始化 ---
board = [...
5 3 0 0 7 0 0 0 0;
6 0 0 1 9 5 0 0 0;
0 9 8 0 0 0 0 6 0;
8 0 0 0 6 0 0 0 3;
4 0 0 8 0 3 0 0 1;
7 0 0 0 2 0 0 0 6;
0 6 0 0 0 0 2 8 0;
0 0 0 4 1 9 0 0 5;
0 0 0 0 8 0 0 7 9];

answer = [ ...
5  3  4  6  7  8  9  1  2;
6  7  2  1  9  5  3  4  8;
1  9  8  3  4  2  5  6  7;
8  5  9  7  6  1  4  2  3;
4  2  6  8  5  3  7  9  1;
7  1  3  9  2  4  8  5  6;
9  6  1  5  3  7  2  8  4;
2  8  7  4  1  9  6  3  5;
3  4  5  2  8  6  1  7  9];

%--- 5. 棋盤與 SSVEP 刺激區域初始化 (正圓環狀排列) ---

% =========================================================================
% 【實驗控制參數】：根據受試者需求自由配置幾何外觀與閃爍波形
% 1. 形狀控制 (stimShape):
%    stimShape = 0 : 使用「圓形」顯示 (Circle / Oval)
%    stimShape = 1 : 使用「方形」顯示 (Square / Rect)
%
% 2. 波形控制 (stimWave):
%    stimWave  = 0 : 使用「正弦波」調變 (Sinusoidal Wave, 平滑灰階亮度漸變)
%    stimWave  = 1 : 使用「方波」調變 (Square Wave, 明暗二值突變切換)
% =========================================================================
stimShape = 0; 
stimWave  = 1; 

screenHeight = rect(4);
screenWidth = rect(3);

% 動態自適應單元格大小 (確保中央棋盤與外圍正圓皆完全落於可視區內)
cellSize = max(28, round(screenHeight * 0.038)); % 1080p 下約 41 像素
boardWidth = 9 * cellSize;
boardHeight = 9 * cellSize;
startX = xCenter - boardWidth / 2;
startY = yCenter - boardHeight / 2;

% SSVEP 刺激目標尺寸
boxW = max(60, round(screenHeight * 0.075)); % 1080p 下約 81 像素
boxH = boxW;
margin = max(25, round(screenHeight * 0.032)); % 棋盤對角最遠頂點與目標邊緣之安全間隔

% =========================================================================
% 【半徑控制參數】：計算外圍 9 個刺激目標之正圓環繞半徑 R
% =========================================================================
% boardCornerDist : 棋盤幾何中心至四個角落頂點之歐氏距離
boardCornerDist = (boardWidth / 2) * sqrt(2); 

% R : 刺激目標中心點至螢幕正中央 (xCenter, yCenter) 之幾何半徑 (單位: 像素)
% 若欲自訂半徑距離，可直接在此變更 (例如加上固定偏移: + 30，或直接指定固定像素值)
R = round(boardCornerDist + boxW / 2 + margin); 
% =========================================================================

% =========================================================================
% 【SSVEP 閃爍頻率設定】：定義 9 個候選數字之特定調變頻率 (單位: Hz)
% 陣列索引 k (1~9) 精確對應數獨填入之目標數字 1~9：
% -------------------------------------------------------------------------
%   數字 1 :  8 Hz  (週期 125.0 ms) | 正上方 12 點鐘 (-90°)
%   數字 2 :  9 Hz  (週期 111.1 ms) | 右上方約 1 點 20 分 (-50°)
%   數字 3 : 10 Hz  (週期 100.0 ms) | 右偏上約 2 點 40 分 (-10°)
%   數字 4 : 11 Hz  (週期  90.9 ms) | 右偏下約 4 點鐘 (+30°)
%   數字 5 : 12 Hz  (週期  83.3 ms) | 右下方約 5 點 20 分 (+70°)
%   數字 6 : 13 Hz  (週期  76.9 ms) | 左下方約 6 點 40 分 (+110°)
%   數字 7 : 14 Hz  (週期  71.4 ms) | 左偏下約 8 點鐘 (+150°)
%   數字 8 : 15 Hz  (週期  66.7 ms) | 左偏上約 9 點 20 分 (+190°)
%   數字 9 : 16 Hz  (週期  62.5 ms) | 左上方約 10 點 40 分 (+230°)
% =========================================================================
freq = [8 9 10 11 12 13 14 15 16];
angles = -pi/2 + (0:8) * (2 * pi / 9); % 360 度正圓均勻分佈 (每隔 40 度，順時針排列)
rects = cell(1, 9);
for k = 1:9
    posX = xCenter + R * cos(angles(k));
    posY = yCenter + R * sin(angles(k));
    rects{k} = CenterRectOnPoint([0 0 boxW boxH], posX, posY);
end

running = true;

%--- 6. 主流程大迴圈 ---
while running
    % 動態搜尋目前棋盤中剩下的所有空格 (等於 0 的位置)
    [row, col] = find(board == 0);
    emptyPos = [row col];
    
    % 若已經沒有空格，代表數獨已全部填完
    if isempty(emptyPos)
        Screen('TextSize', window, 100);
        DrawFormattedText(window, 'Completed!', 'center', 'center', white);
        Screen('Flip', window);
        WaitSecs(2);
        break;
    end
    
    % 【關鍵修正】：永遠鎖定「當前剩餘空格中的第一個」
    targetRow = emptyPos(1, 1);
    targetCol = emptyPos(1, 2);

    % --- 步驟 A：提示當前目標空格 (中央顯示棋盤，四周顯示靜態刺激選項) ---
    Screen('FillRect', window, black);
    
    % 繪製中央數獨棋盤
    Screen('TextSize', window, round(cellSize * 0.55));
    for r = 1:9
        for c = 1:9
            cellRect = [ ...
                startX + (c-1)*cellSize, ...
                startY + (r-1)*cellSize, ...
                startX + c*cellSize, ...
                startY + r*cellSize];
            
            % 當前目標空格標示黃底
            if r == targetRow && c == targetCol
                Screen('FillRect', window, [255 255 0], cellRect);
                Screen('FrameRect', window, [255 255 255], cellRect, 3);
            else
                Screen('FrameRect', window, white, cellRect, 1);
            end
            
            % 顯示已存在與新填入的數字
            if board(r,c) ~= 0
                txt = num2str(board(r,c));
                [cx, cy] = RectCenter(cellRect);
                bounds = Screen('TextBounds', window, txt);
                textW = bounds(3) - bounds(1);
                textH = bounds(4) - bounds(2);
                
                % 若是當前黃格，文字顯示黑色以提升對比
                if r == targetRow && c == targetCol
                    textColor = black;
                else
                    textColor = white;
                end
                
                DrawFormattedText(window, txt, cx - textW/2, cy + textH/2, textColor);
            end
        end
    end
    
    % 繪製 3x3 九宮格粗外框加強結構辨識
    for br = 0:3
        lineY = startY + br * 3 * cellSize;
        Screen('DrawLine', window, white, startX, lineY, startX + boardWidth, lineY, 3);
    end
    for bc = 0:3
        lineX = startX + bc * 3 * cellSize;
        Screen('DrawLine', window, white, lineX, startY, lineX, startY + boardHeight, 3);
    end

    % 繪製四周 9 個靜態刺激目標 (根據 stimShape 選擇圓形或方形)
    Screen('TextSize', window, round(boxH * 0.45));
    for k = 1:9
        if stimShape == 0
            Screen('FillOval', window, [40 40 40], rects{k});
            Screen('FrameOval', window, white, rects{k}, 2);
        else
            Screen('FillRect', window, [40 40 40], rects{k});
            Screen('FrameRect', window, white, rects{k}, 2);
        end
        txtK = num2str(k);
        boundsK = Screen('TextBounds', window, txtK);
        wK = boundsK(3) - boundsK(1);
        hK = boundsK(4) - boundsK(2);
        [cx, cy] = RectCenter(rects{k});
        DrawFormattedText(window, txtK, cx - wK/2, cy + hK/2, white);
    end
    
    Screen('Flip', window);
    WaitSecs(1.5); % 提示當前目標空格 1.5 秒

    % --- 步驟 B：同屏呈現 - SSVEP 閃爍刺激 + 鍵盤即時輸入 ---
    stimDuration = 5;
    selectedNum = 0;
    
    % 清除殘留的鍵盤狀態
    while KbCheck; end
    
    t0 = GetSecs;
    
    while GetSecs - t0 < stimDuration
        t = GetSecs - t0;
        
        % 1. 檢測鍵盤輸入 (直觀判定法)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(escKey)
                running = false;
                break;
            end
            
            % 取得被按下的按鍵名稱
            pressedKeyName = KbName(keyCode);
            
            % 若同時有多鍵按下，取第一個
            if iscell(pressedKeyName)
                pressedKeyName = pressedKeyName{1};
            end
            
            % 比對按鍵名稱中是否包含 1~9 的數字字元
            if ~isempty(pressedKeyName)
                numMatch = regexp(pressedKeyName, '[1-9]', 'match');
                if ~isempty(numMatch)
                    selectedNum = str2double(numMatch{1});
                    break; % 成功抓到數字，立即中斷閃爍
                end
            end
        end
        
        % 2. 畫面渲染：清除背景為黑色
        Screen('FillRect', window, black);
        
        % 2-1. 繪製中央數獨棋盤 (維持當前題目與黃底目標格)
        Screen('TextSize', window, round(cellSize * 0.55));
        for r = 1:9
            for c = 1:9
                cellRect = [ ...
                    startX + (c-1)*cellSize, ...
                    startY + (r-1)*cellSize, ...
                    startX + c*cellSize, ...
                    startY + r*cellSize];
                
                if r == targetRow && c == targetCol
                    Screen('FillRect', window, [255 255 0], cellRect);
                    Screen('FrameRect', window, [255 255 255], cellRect, 3);
                else
                    Screen('FrameRect', window, white, cellRect, 1);
                end
                
                if board(r,c) ~= 0
                    txt = num2str(board(r,c));
                    [cx, cy] = RectCenter(cellRect);
                    bounds = Screen('TextBounds', window, txt);
                    textW = bounds(3) - bounds(1);
                    textH = bounds(4) - bounds(2);
                    
                    if r == targetRow && c == targetCol
                        textColor = black;
                    else
                        textColor = white;
                    end
                    
                    DrawFormattedText(window, txt, cx - textW/2, cy + textH/2, textColor);
                end
            end
        end
        
        % 繪製 3x3 九宮格粗線條
        for br = 0:3
            lineY = startY + br * 3 * cellSize;
            Screen('DrawLine', window, white, startX, lineY, startX + boardWidth, lineY, 3);
        end
        for bc = 0:3
            lineX = startX + bc * 3 * cellSize;
            Screen('DrawLine', window, white, lineX, startY, lineX, startY + boardHeight, 3);
        end
        
        % 2-2. 繪製四周 9 個 SSVEP 閃爍目標 (波形: 正弦波 / 方波; 形狀: 圓形 / 方形)
        Screen('TextSize', window, round(boxH * 0.45));
        for k = 1:9
            if stimWave == 0
                % --- 正弦波模式 (Sinusoidal Wave)：灰階亮度平滑漸變 ---
                sinVal = sin(2 * pi * freq(k) * t);
                intensity = round(50 + (255 - 50) * (1 + sinVal) / 2);
                color = [intensity, intensity, intensity];
                if intensity > 152
                    textColor = black;
                else
                    textColor = white;
                end
            else
                % --- 方波模式 (Square Wave)：高對比明暗二值突變切換 ---
                if sin(2 * pi * freq(k) * t) >= 0
                    color = white;
                    textColor = black;
                else
                    color = [50 50 50];
                    textColor = white;
                end
            end
            
            if stimShape == 0
                Screen('FillOval', window, color, rects{k});
                Screen('FrameOval', window, white, rects{k}, 3);
            else
                Screen('FillRect', window, color, rects{k});
                Screen('FrameRect', window, white, rects{k}, 3);
            end
            
            txtK = num2str(k);
            boundsK = Screen('TextBounds', window, txtK);
            wK = boundsK(3) - boundsK(1);
            hK = boundsK(4) - boundsK(2);
            [cx, cy] = RectCenter(rects{k});
            DrawFormattedText(window, txtK, cx - wK/2, cy + hK/2, textColor);
        end
        
        Screen('Flip', window);
    end
    
    if ~running
        break;
    end
    
    % --- 步驟 C：將鍵盤輸入的數字直接更新寫入 board 矩陣 ---
    if selectedNum > 0
        board(targetRow, targetCol) = selectedNum;
        fprintf('目標空格 (%d,%d) 已填入數字: %d\n', targetRow, targetCol, selectedNum);
        
        % 等待按鍵釋放，防止連續寫入
        while KbCheck; end
    else
        fprintf('未輸入數字，將重新進行該格的填寫與閃爍。\n');
    end
    
    Screen('Flip', window);
    WaitSecs(0.5);
end

sca;
