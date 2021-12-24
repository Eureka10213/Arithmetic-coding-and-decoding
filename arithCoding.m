clc
sym=['a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n' 'o' 'p' 'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z' ' ' ];
p=[0.0575 0.0128 0.0263 0.0285 0.0913 0.0173 0.0133 0.0313 0.0599 0.0006 0.0084 0.0335 0.0235 0.0596 0.0689 0.0192 0.0008 0.0508 0.0567 0.0706 0.0334 0.0069 0.0119 0.0073 0.0164 0.0007 0.1928];
allmessage=fileread('send.txt');% Read the message from send.txt
allmessage=lower(allmessage);%Turn uppercase letters into lowercase
allmessage=regexprep(allmessage,{','},' ');%Remove the comma, if other punctuation, please remove
code1= arithCode(allmessage,sym,p,5);%Code, 5 letters each time
decode1=arithDecode(code1,sym,p,5);% decode
fid=fopen('result.txt','w');%Store the decoding result in result.txt
fprintf(fid,'%s',decode1);
fclose(fid);

%The following are the functions used and their specific instructions
%arithmetic coding
function [ codeBin ] = arithCode( message,alphaDic,alphaProb,symNum)
%Arithmetic coding of the input message sequence
%  codeBin Output binary code sequence
%  message  Input message sequence
%  alphaDic  Source symbol collection 
%  alphaProb  Probability corresponding to source symbol
%  symNum    How many symbols are encoded in an arithmetic encoding
probValOri(1)=0;% The starting point of the interval corresponding to the letter a is 0
for i=1:length(alphaDic)
    probValOri(i+1)=probValOri(i)+alphaProb(i);%Corresponding letters to different probability intervals on [0,1] according to probability distribution to generate probability axis
end
totalLen=length(message);%The length of the message to be encoded
operaNum=floor(totalLen/symNum);%Quotient is an integer, which is the number of encoding; if it is not an integer, it is the number of encoding -1
restSymNum=mod(totalLen,symNum);%The number of letters to be processed in the last arithmetic coding
codeBin=[];% Encoded binary sequence
%Traverse according to the number of times
for k=0:operaNum-1
    left=0;%Interval left
    valLen=1;%Interval length
    probVal=probValOri;
    shortMes=message(k*symNum+1:(k+1)*symNum);%Process symNum letters at a time
    %The coding process of symNum letters each time is as follows
    for i=1:symNum
        left=left+probVal(find(alphaDic==shortMes(i)));%Determine the position of the i-th letter on the probability axis, left bound
        right=left+alphaProb(find(alphaDic==shortMes(i)))*valLen;%The probability corresponding to the left bound plus this letter is the right bound
                                                              %Every time encoding is performed, the original probability distribution must be multiplied by the interval length to reduce
        valLen=right-left;
        probVal=probValOri*valLen;%The probability axis should also be reduced in accordance with the length of the interval to prepare for the next letter code  
    end
    middle=0.5*(right+left)%Compiled decimal
    codeLen=calcCodeLen(alphaProb,alphaDic,shortMes);%Calculate code length
    shortCodeBin=deciConvertBin(middle,2*codeLen);%Convert decimals into a binary sequence of specified length
    shortCodeBin=[shortCodeBin ' '];%After each encoding is completed, add a space at the end to separate the next sequence
    codeBin=[codeBin shortCodeBin];%Store the coding sequence in
    shortCodeBin=[];
end
%If the quotient is not 0, encode the last remaining letter
if(restSymNum~=0)
    left=0;
    valLen=1;
    probVal=probValOri;
    for j=totalLen-restSymNum+1:totalLen
        left=left+probVal(find(alphaDic==message(j)));
        right=left+alphaProb(find(alphaDic==message(j)))*valLen;
        valLen=right-left;
        probVal=probValOri.*valLen;
    end
    middle=0.5*(right+left); 
    codeLen=calcCodeLen(alphaProb,alphaDic,message(totalLen-restSymNum+1:totalLen));
    shortCodeBin=deciConvertBin(middle,2*codeLen);
    shortCodeBin=[shortCodeBin ' '];
    codeBin=[codeBin shortCodeBin];
end
end

%arithmetic decoding
function [ mesDecode] = arithDecode(codeBin,alphaDic,alphaProb,symNum )
%  Arithmetic decoding of the compiled binary sequence
%  codeBin codeBin is a compiled binary sequence
%  alphaDic   Source symbol collection
%  alphaProb   Probability corresponding to source symbol
%  mesDecode  Output decoded message
%  symNum     How many symbols are encoded in an arithmetic encoding
shortMes=[];mesDecode=[];shortCodeBin=[];%The message obtained by decoding at one time,
                                        %all messages, and the binary sequence to be processed by decoding at one time

%Every time a space is detected, stop reading numbers into shortCodeBin,and decode the binary sequence that has been read
for i=1:length(codeBin)
    if(codeBin(i)~=' ')
        shortCodeBin=[shortCodeBin codeBin(i)];
    else
        codeDec=deciConvertDec(shortCodeBin);%Convert a binary sequence to a decimal number
        probValOri(1)=0;
        % According to the probability distribution of the letters, the probability axis is generated
        for j=1:length(alphaDic)
            probValOri(j+1)=probValOri(j)+alphaProb(j);
        end
        left=0;
        val=1;
        probVal=probValOri;
        %Known to process symNum letters at a time
        for k=1:symNum
            %By judging which interval codeDec is in the probability axis, judge what the letter is
            for m=1:length(alphaDic)
                if(codeDec>=left+probVal(m)&&codeDec<=left+probVal(m+1))
                    shortMes=[shortMes alphaDic(m)];
                    break;
                end
            end
            %Every time a letter is decoded, the interval length, left boundary and probability axis are updated
            val=probVal(m+1)-probVal(m);
            left=left+probVal(m);
            probVal=probValOri.*val;    
        end
        mesDecode=[mesDecode shortMes];
        shortMes=[];
        shortCodeBin=[];
    end
end
end

%Calculate the code length
function [ codeLen ] = calcCodeLen(prob,alpha,message) 
%Calculate the code length, according to the information theory,
%calculate the amount of information of a string, the unit is bit
multiProb=1;
for i=1:length(message)
    multiProb=multiProb*prob(find(alpha==message(i)));
end
codeLen=ceil(-log2(multiProb));
end

%Convert a decimal number into a binary sequence of specified length
function [ bin ] = deciConvertBin( deci,codeLen )
%Convert a decimal number into a binary sequence of specified length
%There is a bug in this code, that is, it does not 
%consider the carry when bin is all 1.
bins=[];
for i=1:codeLen
    deci=2*deci;
    inte=floor(deci);
    deci=deci-inte;
    inteStr=num2str(inte);
    bins=[bins inteStr];
end
for j=codeLen:-1:1
    if(bins(j)=='0')
        bins(j)='1';
        break;
    else
        bins(j)='0';
    end
end 
bin=bins;
end

%Convert binary decimals to decimal decimals
function [ dec ] = deciConvertDec(bin )
%Convert binary decimals to decimal decimals (between 0 and 1)
bins=[];
for j=1:length(bin)
    bins(j)=str2num(bin(j));
end
dec=0;
for i=1:length(bins)
    dec=dec+2.^(-i)*bins(i);
end
end





