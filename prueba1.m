clear;

% camera = webcam;
nnet = alexnet;

% while true
%     picture=camera.snapshot;
    picture = imread('coche.jpg');
    picture= imresize(picture,[227,227]);
    label=classify(nnet,picture);
    
    label=classify(nnet,picture);
    image(picture);
    title(char(label));
    drawnow;
% end

    if (label == 'racer')
        f = msgbox('Gilipollas');
    end
        
        