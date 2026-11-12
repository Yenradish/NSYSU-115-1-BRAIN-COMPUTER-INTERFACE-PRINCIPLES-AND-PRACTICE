function SSVEP_Single_Stimulus_Test()
% =========================================================================
% SSVEP 單一目標刺激驗證與精確計時測試平台 (100% Psychtoolbox-3 原生驅動)
% 特色：高階抗鋸齒繁體中文 HUD 儀表板 (思源黑體 / 微軟正黑體)、6 種主流調變技術
% =========================================================================

close all;
clear;
sca;
clc;

% 1. 基本環境初始化與按鍵設定
KbName('UnifyKeyNames');
escKey   = KbName('ESCAPE');
upKey    = KbName('UpArrow');
downKey  = KbName('DownArrow');
leftKey  = KbName('LeftArrow');
rightKey = KbName('RightArrow');

key1 = KbName('1!');
if isempty(key1); key1 = KbName('1'); end
key2 = KbName('2@');
if isempty(key2); key2 = KbName('2'); end
key3 = KbName('3#');
if isempty(key3); key3 = KbName('3'); end
key4 = KbName('4$');
if isempty(key4); key4 = KbName('4'); end
key5 = KbName('5%');
if isempty(key5); key5 = KbName('5'); end
key6 = KbName('6^');
if isempty(key6); key6 = KbName('6'); end

% =========================================================================
% 【核心測試參數配置】
% =========================================================================
targetFreq    = 10.0;     % 目標閃爍頻率 (單位: Hz)
boxSize       = 500;      % 刺激方塊尺寸 (單位: 像素，正方形寬高)
stimMode      = 1;        % 預設閃爍模式 (1: 正弦波, 2: 標準方波, 3: 整數幀方波, 4: 棋盤翻轉, 5: 占空比方波, 6: 紅綠交替)
dutyCycle     = 0.3;      % 模式 5 專用占空比 (0.1 ~ 0.9，預設 30% 亮)
checkerRows   = 8;        % 模式 4 棋盤格橫向格數
checkerCols   = 8;        % 模式 4 棋盤格縱向格數

% 亮度上下限配置 (0 ~ 255)
minLum = 0;
maxLum = 255;

% 2. 顯示器與視窗初始化
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 3);
Screen('Preference', 'SuppressAllWarnings', 1);

screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

[window, rect] = Screen('OpenWindow', screenNumber, black);
[xCenter, yCenter] = RectCenter(rect);

% 開啟 OpenGL Alpha Blending 確保紋理文字邊緣平滑抗鋸齒
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% 3. 精確量測螢幕垂直更新週期 (Inter-Frame Interval, ifi)
ifi = Screen('GetFlipInterval', window, 100);
nominalRefreshRate = Screen('NominalFrameRate', window);
measuredRefreshRate = 1 / ifi;

% 4. 預先建立棋盤格紋理 (用於模式 4，使用內建 kron 避免工具箱相依性)
cellH = ceil(boxSize / checkerRows);
cellW = ceil(boxSize / checkerCols);
baseGrid = mod((1:checkerRows)' + (1:checkerCols), 2);
fullGrid = kron(baseGrid, ones(cellH, cellW));
checkMat1 = fullGrid(1:boxSize, 1:boxSize) > 0.5;
checkMat2 = ~checkMat1;
texChecker1 = Screen('MakeTexture', window, uint8(checkMat1 * 255));
texChecker2 = Screen('MakeTexture', window, uint8(checkMat2 * 255));

% =========================================================================
% 5. 預先建立高畫質繁體中文 HUD 紋理 (思源黑體 / 微軟正黑體 UI)
% =========================================================================
modeChineseNames = {
    '當前模式 [1]: 取樣正弦波灰階調變 (Sampled Sinusoid)'
    '當前模式 [2]: 標準方波明暗調變 (Standard Square Wave - 50% 占空比)'
    '當前模式 [3]: 整數幀對齊方波 (Exact Integer Frame Square)'
    '當前模式 [4]: 棋盤格空間反轉 (Checkerboard Pattern Reversal)'
    '當前模式 [5]: 自訂占空比脈衝方波 (Duty-Cycle Pulse PWM)'
    '當前模式 [6]: 等明度紅綠交替調變 (Chromatic Red-Green Flicker)'
};

modeTex = zeros(1, 6);
modeRect = cell(1, 6);
for k = 1:6
    [modeTex(k), modeRect{k}] = createTextTexture(window, modeChineseNames{k}, 19, [255 220 50], 35, 22);
end

menuStr = '模式切換：[1] 正弦波  [2] 標準方波  [3] 整數幀方波  [4] 棋盤格  [5] 占空比脈衝  [6] 紅綠交替';
[texMenu, rectMenu] = createTextTexture(window, menuStr, 15, [160 215 255], 35, 56);

hotkeyStr = '控制熱鍵：[上/下] 調整頻率 (+/- 0.5 Hz)   [左/右] 調整尺寸 (+/- 50 px)   [ESC] 退出測試';
[texHotkeys, rectHotkeys] = createTextTexture(window, hotkeyStr, 15, [220 220 220], 35, 88);

% HUD 卡片背景矩形 (左上方半透明視窗，確保與中央刺激方塊互不干擾)
hudRect = [20, 14, 980, 152];

% =========================================================================
% 6. 開場視覺流程 (完全對齊 BCI_final_YEH.m)
% =========================================================================
% 6-1. 開始畫面
Screen('TextSize', window, 90);
DrawFormattedText(window, 'Press any key to start', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

% 6-2. 倒數計時
Screen('TextSize', window, 150);
for countdown = 3:-1:1
    Screen('FillRect', window, black);
    DrawFormattedText(window, num2str(countdown), 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(1);
end

% 6-3. 注視點 (Fixation Cross)
Screen('FillRect', window, black);
Screen('TextSize', window, 350);
DrawFormattedText(window, '+', 'center', 'center', white);
Screen('Flip', window);
WaitSecs(0.5);

% =========================================================================
% 7. 主渲染迴圈計時變數與精確排程
% =========================================================================
vbl = Screen('Flip', window);
tStart = vbl;
frameIndex = 0;
missedCount = 0;
prevKeyIsDown = false;

running = true;

while running
    % --- A. 鍵盤事件處理 (非阻塞邊緣觸發) ---
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && ~prevKeyIsDown
        if keyCode(escKey)
            running = false;
        elseif keyCode(key1)
            stimMode = 1;
        elseif keyCode(key2)
            stimMode = 2;
        elseif keyCode(key3)
            stimMode = 3;
        elseif keyCode(key4)
            stimMode = 4;
        elseif keyCode(key5)
            stimMode = 5;
        elseif keyCode(key6)
            stimMode = 6;
        elseif keyCode(upKey)
            targetFreq = targetFreq + 0.5;
        elseif keyCode(downKey)
            targetFreq = max(1.0, targetFreq - 0.5);
        elseif keyCode(rightKey)
            boxSize = min(rect(4) - 180, boxSize + 50);
        elseif keyCode(leftKey)
            boxSize = max(100, boxSize - 50);
        end
    end
    prevKeyIsDown = keyIsDown;
    
    % --- B. 計算當前時間戳記與相位 ---
    t = vbl - tStart;
    stimRect = CenterRectOnPoint([0 0 boxSize boxSize], xCenter, yCenter);
    framesPerCycle = measuredRefreshRate / targetFreq;
    
    % --- C. 根據選擇模式計算渲染內容 ---
    switch stimMode
        case 1
            % 【模式 1】：取樣正弦波灰階調變 (Sampled Sinusoidal Modulation)
            sinVal = sin(2 * pi * targetFreq * t);
            intensity = round(minLum + (maxLum - minLum) * (1 + sinVal) / 2);
            Screen('FillRect', window, [intensity, intensity, intensity], stimRect);
            
        case 2
            % 【模式 2】：標準方波明暗調變 (Standard Square Wave)
            phase = mod(targetFreq * t, 1.0);
            if phase < 0.5
                color = [maxLum, maxLum, maxLum];
            else
                color = [minLum, minLum, minLum];
            end
            Screen('FillRect', window, color, stimRect);
            
        case 3
            % 【模式 3】：整數幀對齊方波 (Exact Integer Frame Square Wave)
            halfCycleFrames = round(framesPerCycle / 2);
            currentCycleFrame = mod(frameIndex, 2 * halfCycleFrames);
            if currentCycleFrame < halfCycleFrames
                color = [maxLum, maxLum, maxLum];
            else
                color = [minLum, minLum, minLum];
            end
            Screen('FillRect', window, color, stimRect);
            
        case 4
            % 【模式 4】：棋盤格空間反轉 (Checkerboard Pattern Reversal)
            phase = mod(targetFreq * t, 1.0);
            if phase < 0.5
                Screen('DrawTexture', window, texChecker1, [], stimRect);
            else
                Screen('DrawTexture', window, texChecker2, [], stimRect);
            end
            
        case 5
            % 【模式 5】：可自訂占空比脈衝方波 (Duty-Cycle Pulse PWM)
            phase = mod(targetFreq * t, 1.0);
            if phase < dutyCycle
                color = [maxLum, maxLum, maxLum];
            else
                color = [minLum, minLum, minLum];
            end
            Screen('FillRect', window, color, stimRect);
            
        case 6
            % 【模式 6】：等明度色彩交替調變 (Chromatic Red-Green Modulation)
            phase = mod(targetFreq * t, 1.0);
            if phase < 0.5
                color = [255, 0, 0];
            else
                color = [0, 255, 0];
            end
            Screen('FillRect', window, color, stimRect);
    end
    
    % --- D. 外框與繁體中文 HUD 儀表板渲染 (分層清晰、互不重疊) ---
    Screen('FrameRect', window, [100 100 100], stimRect, 2);
    
    % 1. 繪製 HUD 半透明背景卡片
    Screen('FillRect', window, [18 20 28], hudRect);
    Screen('FrameRect', window, [55 65 80], hudRect, 1);
    
    % 2. 繪製當前模式名稱 (第一行，黃色思源黑體)
    Screen('DrawTexture', window, modeTex(stimMode), [], modeRect{stimMode});
    
    % 3. 繪製模式切換清單 (第二行，淺藍色)
    Screen('DrawTexture', window, texMenu, [], rectMenu);
    
    % 4. 繪製控制熱鍵指南 (第三行，淺灰色)
    Screen('DrawTexture', window, texHotkeys, [], rectHotkeys);
    
    % 5. 繪製即時數值監測 (第四行，獨立高度 y = 120，螢光綠色)
    Screen('TextSize', window, 16);
    dynamicStats = sprintf('Target: %.2f Hz | Frames/Cycle: %.2f | Refresh: %.2f Hz | Size: %d px | Missed: %d', ...
        targetFreq, framesPerCycle, measuredRefreshRate, boxSize, missedCount);
    DrawFormattedText(window, dynamicStats, 35, 122, [130 255 130]);
    
    % --- E. 關鍵精確時間同步垂直翻頁 ---
    [vbl, ~, ~, missed] = Screen('Flip', window, vbl + 0.5 * ifi);
    
    frameIndex = frameIndex + 1;
    if missed > 0 && frameIndex > 1
        missedCount = missedCount + 1;
    end
end

% 8. 釋放所有紋理與視窗資源
Screen('Close', texChecker1);
Screen('Close', texChecker2);
Screen('Close', texMenu);
Screen('Close', texHotkeys);
for k = 1:6
    Screen('Close', modeTex(k));
end
sca;

% 9. 命令視窗輸出診斷統計
fprintf('\n================== SSVEP 測試診斷結果 ==================\n');
fprintf('螢幕量測更新率: %.4f Hz\n', measuredRefreshRate);
fprintf('最後測試目標頻率: %.2f Hz\n', targetFreq);
fprintf('最後測試模式: [%d] %s\n', stimMode, modeChineseNames{stimMode});
fprintf('總渲染幀數: %d\n', frameIndex);
fprintf('掉幀次數 (Missed Flips): %d (%.2f%%)\n', missedCount, (missedCount / max(1, frameIndex)) * 100);
fprintf('理論每週期幀數 (RefreshRate / TargetFreq): %.4f 幀\n', measuredRefreshRate / targetFreq);
if abs(round(measuredRefreshRate / targetFreq) - (measuredRefreshRate / targetFreq)) > 0.05
    fprintf('【警告】：目標頻率無法被螢幕更新率整除！在方波模式下必然產生相位抖動 (Phase Jitter)。\n');
    fprintf('         建議選用能被 %.1f Hz 整除的頻率，或採用正弦波調變 (模式 1)。\n', measuredRefreshRate);
else
    fprintf('【正常】：目標頻率可被螢幕更新率整除，能呈現穩定的對稱方波。\n');
end
fprintf('========================================================\n\n');

end

% =========================================================================
% 輔助函式：高畫質抗鋸齒繁體中文 RGBA 紋理產生器 (思源黑體 / 微軟正黑體 UI)
% =========================================================================
function [tex, rect] = createTextTexture(window, txt, fontSize, fontColor, posX, posY)
    import java.awt.*;
    import java.awt.image.*;
    
    % 優先採用系統最佳繁體中文無襯線字型 (Noto Sans TC / 思源黑體，備援微軟正黑體 UI)
    fontName = 'Noto Sans TC';
    font = Font(fontName, Font.BOLD, fontSize);
    if strcmp(char(font.getFamily()), 'Dialog')
        font = Font('Microsoft JhengHei UI', Font.BOLD, fontSize);
    end
    
    dummyImg = BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
    g2d = dummyImg.createGraphics();
    g2d.setFont(font);
    metrics = g2d.getFontMetrics();
    textW = metrics.stringWidth(txt) + 16;
    textH = metrics.getHeight() + 8;
    ascent = metrics.getAscent();
    g2d.dispose();
    
    img = BufferedImage(textW, textH, BufferedImage.TYPE_INT_ARGB);
    g2d = img.createGraphics();
    % 開啟全域高品質文字與向量抗鋸齒渲染提示
    g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
    g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
    g2d.setFont(font);
    g2d.setColor(Color(fontColor(1)/255, fontColor(2)/255, fontColor(3)/255));
    g2d.drawString(txt, 8, ascent + 4);
    g2d.dispose();
    
    pixels = int64(img.getRGB(0, 0, textW, textH, [], 0, textW));
    a = bitshift(bitand(pixels, int64(hex2dec('FF000000'))), -24);
    r = bitshift(bitand(pixels, int64(hex2dec('00FF0000'))), -16);
    g = bitshift(bitand(pixels, int64(hex2dec('0000FF00'))), -8);
    b = bitand(pixels, int64(hex2dec('000000FF')));
    
    rgbaMat = zeros(textH, textW, 4, 'uint8');
    rgbaMat(:, :, 1) = reshape(uint8(r), textW, textH)';
    rgbaMat(:, :, 2) = reshape(uint8(g), textW, textH)';
    rgbaMat(:, :, 3) = reshape(uint8(b), textW, textH)';
    rgbaMat(:, :, 4) = reshape(uint8(a), textW, textH)';
    
    tex = Screen('MakeTexture', window, rgbaMat);
    rect = [posX, posY, posX + textW, posY + textH];
end
