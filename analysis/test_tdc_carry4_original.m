clear all;%-22稳定在-19度,dianliu 1.32A
clc 
data=textread('C:\Users\ThinkPad\Desktop\tdc_carry4\22_30.txt','%s');

m=1;
n=1;
for i=1:size(data,1)
    if size(data{i,1},2)==2
        c=data{i,1};
        if c(1,1)=='.'
        else
            b(m,1)=hex2dec(data(i,1));          
            m=m+1;
        end
    end
end
num=0;
a1=0;
a2=0;
a3=0;
a4=0;
a5=0;
a6=0;
a7=0;
a8=0;
a9=0;
a10=0;
a11=0;
n=0;
for i=1:(length(b)/5-1)

  
      
 stop_count(i)=b((i-1)*5+2);
 stop_phase(i)=b((i-1)*5+3);
      
  trig_count(i)=b((i-1)*5+4);
  trig_phase(i)=b((i-1)*5+5);     
      
      
  if( trig_phase(i) == 0)
       trig_phase(i) =50;
  end
  
  if( stop_phase(i) == 0)
       stop_phase(i) =50;
  end  
  
   if(trig_count(i)>stop_count(i))    
       stop_count(i)=stop_count(i)+256;
   end
  bbb(i)=trig_phase(i)- stop_phase(i);
      aaa(i)=stop_count(i)- trig_count(i);
   delay_time(i)=    (stop_count(i)- trig_count(i))*50*72 +  (trig_phase(i)- stop_phase(i))*72;
      
      
        
end

for i=1:8000
    n_1=i*72;
    
  ayyy1(i)=length(find(delay_time==n_1));

  
  
  axxx(i)=n_1/1000;

end




 standard_1=std(delay_time,1)/(sqrt(2))

hold on
figure(5)
 plot(axxx,ayyy1)




