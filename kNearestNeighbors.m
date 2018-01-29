function [index weight] = kNearestNeighbors(k, list, elevation, azimuth)
    index = [];
    distance = [];
    smallestDistance = 87123876123897;
    for i = 1:length(list)
        d = abs(list(i, 1) - elevation) + min([abs(list(i, 2) - azimuth) abs(list(i, 2) - (azimuth - 360))]);
        if (d < smallestDistance)
            smallestDistance = d;
            index = [i index];
            distance = [d distance];
        end
    end
    %disp([elevation azimuth smallestDistance length(index)]);
    assert (length(index) >= k);
    index = index(1:k);
    distance = distance(1:k);
    weight = distance / sum(distance);
    weight = 1 - weight;
    weight = weight / sum(weight);
end