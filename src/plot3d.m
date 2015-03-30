%plotting particles in
clear alll; close all; clc;
load pos.out
part = zeros(4,1000,3);
for jj = 1:4
    for ii = 1:1000
        part(jj,ii,1) = pos((jj-1)*1000+ii,1);
        part(jj,ii,2) = pos((jj-1)*1000+ii,2);
        part(jj,ii,3) = pos((jj-1)*1000+ii,3);
    end 
end
figure(1)
scatter3(part(1,:,1),part(1,:,2),part(1,:,3))
hold on 
scatter3(part(2,:,1),part(2,:,2),part(2,:,3))
hold on 
scatter3(part(3,:,1),part(3,:,2),part(3,:,3))
hold on 
scatter3(part(4,:,1),part(4,:,2),part(4,:,3))