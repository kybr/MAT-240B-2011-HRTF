% MAT 240B - 2011/03/18 - Karl Yerkes
%
% this code was written in an effort to prototype an online, realtime
% hrtf-based binaural spatializer.  the evetual goal is to run this
% spatializer on an iPhone as part of the AlloScope project, started
% by Danny Bazo and Karl Yerkes, in the Winter of 2010.
%
% this code uses a weighted sum of the 4 HRTFs that are nearest to the
% given elevation and azimuth.
%

% clear out junk
%
clear;
clc;

% choose some settings
%
fileName = 'computerNoise.wav';
%fileName = 'dc.wav'; % use this for testing
numberOfBlocks = 1800;
blockSize = 512;
hopSize = blockSize / 2;
window = hann(blockSize);

% allocate a stereo output file, open the input file, play and plot
%
output = zeros(numberOfBlocks * blockSize, 2);
[inputFile sampleRate sampleDepth] = wavread(fileName);
fileLength = length(inputFile);
assert(fileLength > blockSize);
sound(inputFile, sampleRate, sampleDepth);
figure(1), plot(inputFile);

% this should let us always get another block of source, looping
%
inputFile = [inputFile ; inputFile(1:blockSize)];
nextBlock = @(i) ...
    inputFile(mod(i, fileLength):(mod(i, fileLength) + blockSize - 1));

% load up some HRIR data and take the fft. right now the fft size is
% the same as the length of the HRIRs, 512. a better man would make this
% a configurable parameter. the file IRC_1022_C_HRIR.mat was downloaded
% from the IRCAM HRTF site:
%   http://recherche.ircam.fr/equipes/salles/listen/download.html
%
load('IRC_1022_C_HRIR.mat');
assert (l_eq_hrir_S.sampling_hz == sampleRate);
LHRTF = fft(l_eq_hrir_S.content_m');
RHRTF = fft(r_eq_hrir_S.content_m');
elevationAzimuthTable = [l_eq_hrir_S.elev_v l_eq_hrir_S.azim_v];

% the intent of this code is to prototype a scheme for online, realtime
% hrtf-based binaural spatialization. for that reason, this main loop
% processes one block of source material at a time, as you would do in
% an audio callback.  the output is delayed by one hopSize with respect
% to the input material.
%
azimuth = 60; % 0 -> 360 (degrees)
elevation = 15; % -45 -> 90 (degrees)
sourceBlock = zeros(blockSize, 1);
left = sourceBlock;
right = sourceBlock;
for sampleNumber = 1 : blockSize : (numberOfBlocks * blockSize)

    % update elevation and azimuth
    %
    previousElevation = elevation;
    previousAzimuth = azimuth;
    elevation = 15 * sin(azimuth * 2 * pi / 180);
    azimuth = mod(azimuth + 1, 360);

    % calculate interpolated HRTF for the current block and a hop back
    %
    [index weight] = ...
        kNearestNeighbors(4, elevationAzimuthTable, elevation, azimuth);

    hrtfLeft = sum(LHRTF(:, index) .* repmat(weight, 512, 1), 2);
    hrtfRight = sum(RHRTF(:, index) .* repmat(weight, 512, 1), 2);

    [index weight] = ...
        kNearestNeighbors(4, elevationAzimuthTable, ...
        (previousElevation + elevation) / 2, ...
        (previousAzimuth + azimuth) / 2);

    hrtfLeftHopBack = sum(LHRTF(:, index) .* repmat(weight, 512, 1), 2);
    hrtfRightHopBack = sum(RHRTF(:, index) .* repmat(weight, 512, 1), 2);

    % grab the next block of source, but keep the previous block of source
    % because we'll need it next time to calculate the output for the
    % hopBack block.
    %
    previousSourceBlock = sourceBlock;
    sourceBlock = nextBlock(sampleNumber);

    % calculate the time-domain output for this block of source, but keep
    % the previously calculated left and right because we'll need them
    % next time.
    %
    previousLeft = left;
    previousRight = right;
    left = window .* ifft(hrtfLeft .* fft(sourceBlock));
    right = window .* ifft(hrtfRight .* fft(sourceBlock));

    % calculate the time-domain output for one hop ago. for this, we'll
    % need the previous block of source
    %
    halfBackBlock = [ % column vector syntax. watch out!
        previousSourceBlock(hopSize:end)
        sourceBlock(1:(hopSize - 1))
        ];
    leftHopBack = window .* ifft(hrtfLeftHopBack .* fft(halfBackBlock));
    rightHopBack = window .* ifft(hrtfRightHopBack .* fft(halfBackBlock));

    % calculate the output. the ouput is a cross-faded sum of the
    % calculated output for the current source block, the previous source
    % block and the source block one hop ago. this means that our output
    % is delayed hopSize/sampleRate seconds with respect to the source
    % material.
    %
    output(sampleNumber:(sampleNumber + blockSize - 1), 1) = ...
        leftHopBack + ...
        [previousLeft(hopSize:end) ; left(1:(hopSize - 1))];
    output(sampleNumber:(sampleNumber + blockSize - 1), 2) = ...
        rightHopBack + ...
        [previousRight(hopSize:end) ; right(1:(hopSize - 1))];
end

figure(2), plot(output);
sound(output, sampleRate, sampleDepth);
