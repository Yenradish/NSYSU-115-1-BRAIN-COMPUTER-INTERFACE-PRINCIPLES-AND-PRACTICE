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

cellSize = 60;
boardWidth = 9 * cellSize;
boardHeight = 9 * cellSize;
startX = xCenter - boardWidth/2;
startY = yCenter - boardHeight/2;

% SSVEP 刺激區域初始化
freq = [8 9 10 11 12 13 14 15 16];
boxW = 150;
boxH = 150;
dx = 250;
dy = 200;
rects = cell(1, 9);
idx = 1;
for r = 1:3
    for c = 1:3
        rects{idx} = CenterRectOnPoint(...
            [0 0 boxW boxH], ...
            xCenter + (c-2)*dx, ...
            yCenter + (r-2)*dy);
        idx = idx + 1;
    end
end

running = true;

%--- 5. 主流程大迴圈 ---
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

    % --- 步驟 A：繪製當前數獨棋盤 (包含先前已填入的數字) ---
    Screen('FillRect', window, black);
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
                Screen('TextSize', window, round(cellSize*0.5));
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
                
                DrawFormattedText(window, txt, cx-textW/2, cy+textH/2, textColor);
            end
        end
    end
    Screen('Flip', window);
    WaitSecs(1.5); % 提示當前目標空格 1.5 秒

    % --- 步驟 B：SSVEP 閃爍刺激 + 鍵盤即時輸入 ---
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
        
        % 2. 繪製 9 個 SSVEP 正弦波閃爍方格
        Screen('FillRect', window, black);
        Screen('TextSize', window, 50);
        for k = 1:9
            if sin(2*pi*freq(k)*t) > 0
                color = white;
                textColor = black;
            else
                color = [50 50 50];
                textColor = white;
            end
            Screen('FillRect', window, color, rects{k});
            Screen('FrameRect', window, white, rects{k}, 3);
            [cx, cy] = RectCenter(rects{k});
            DrawFormattedText(window, num2str(k), cx-15, cy-25, textColor);
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
        % 【關鍵修正】：移除 currentIdx 遞增邏輯，讓下一次 find(board==0) 自動捉下一格
        
        % 等待按鍵釋放，防止連續寫入
        while KbCheck; end
    else
        fprintf('未輸入數字，將重新進行該格的填寫與閃爍。\n');
    end
    
    Screen('Flip', window);
    WaitSecs(0.5);
end

sca;