RPI=0.016; % old RPI rate
courselength=3; % no. of years of undergraduate study
tuition=9000; % annual undergraduate tuition fee loan in £
studied=1;
undergraduatebalance=0;
maintenance=[3575;3610;3469]; % each year of maintenance loan in £
while studied<=courselength
    undergraduatebalance=(undergraduatebalance+tuition+maintenance(studied))*(1+RPI); % total undergraduate loan borrowed in £, has been accumulating interest during study
    studied=studied+1;
end
startingpostgraduatebalance=10000; % postgraduate loan amount in £
postgraduatebalance=startingpostgraduatebalance;
startingtotalbalance=undergraduatebalance+postgraduatebalance;
totalbalance=startingtotalbalance;
salary=28000; % annual salary in £
threshold=25000; % repayment salary threshold in £
RPI=0.031; % current rate of inflation (rose from 1.6-3.1% in the last year, may rise further)
month=0;
never=0;
already=0;
duration=35*12;
MONTHS=zeros(1,duration); % pre-allocating for speed
UNDERGRADUATEBALANCE=zeros(1,duration);
POSTGRADUATEBALANCE=zeros(1,duration);
BALANCE=zeros(1,duration);
MONTHLYEARNINGS=zeros(1,duration);
MONTHLYREPAYMENTS=zeros(1,duration);
SALARY=zeros(1,duration);
TOTALREPAID=zeros(1,duration);
NETREPAYMENTS=zeros(1,duration);
while month<=duration
    if month==33*12+7 && undergraduatebalance~=0 % loan gets wiped 30 years after April following graduation
        undergraduatebalance=0;
        fprintf('You will never repay your entire student loan. Your starting balance is £%.2f, your remaining balance will be £%.2f, total amount repaid will be £%.2f.\n',startingtotalbalance,totalbalance,sum(MONTHLYREPAYMENTS))
        never=1;
    elseif month==34*12+7
        postgraduatebalance=0;
    end
    if salary-threshold>0
        extra=(salary-threshold)*0.0000015; % extra interest paid due to salary
        if extra>0.03 % extra interest capped at 3%
            extra=0.03;
        end
        undergraduaterepayment=(salary-threshold)*0.09; % amount paid back per year towards undergraduate debt
        postgraduaterepayment=(salary-threshold)*0.06; % amount paid back per year towards postgraduate debt
    else
        extra=0;
        undergraduaterepayment=0;
        postgraduaterepayment=0;
    end
    if month<7
        undergraduaterepayment=0; % won't start paying back until April 2018
    end
    if month<19
        postgraduaterepayment=0; % won't start paying back until April 2019
    end
    if undergraduatebalance>0
        undergraduatebalance=undergraduatebalance-undergraduaterepayment/12; % monthly repayments
        if undergraduatebalance<0
            undergraduatebalance=0; % balance can't be negative, to account for slight overpayment on last instalment
        end
    else
        undergraduaterepayment=0;
    end
    if postgraduatebalance>0
        postgraduatebalance=postgraduatebalance-postgraduaterepayment/12;
    elseif postgraduatebalance<0
        postgraduatebalance=0;
        fprintf('You will repay your postgraduate loan after %d years and %d months.\n',fix(month/12)-4,rem(month,12))
    else
        postgraduaterepayment=0;
    end
    undergraduateinterestpercent=RPI+extra; % interest percentage
    postgraduateinterestpercent=RPI+0.03; % extra interest flat 3% for postgraduate loan
    if mod(month,12)==0
        salary=salary*(1+RPI+0.02); % assuming salary rises every year by inflation + 2% (optimistic)
    end
    undergraduateinterestpounds=undergraduateinterestpercent*undergraduatebalance; % how much undergraduate balance will rise by due to interest in £
    postgraduateinterestpounds=postgraduateinterestpercent*postgraduatebalance; % how much postgraduate balance will rise by due to interest in £
    undergraduatebalance=undergraduatebalance+undergraduateinterestpounds/12; % accounting for interest after repayments i.e. best case scenario
    postgraduatebalance=postgraduatebalance+postgraduateinterestpounds/12;
    totalbalance=undergraduatebalance+postgraduatebalance;
    month=month+1;
    MONTHS(month)=month;
    UNDERGRADUATEBALANCE(month)=undergraduatebalance;
    POSTGRADUATEBALANCE(month)=postgraduatebalance;
    BALANCE(month)=totalbalance;
    MONTHLYEARNINGS(month)=salary/12;
    MONTHLYREPAYMENTS(month)=(undergraduaterepayment+postgraduaterepayment)/12;
    NETREPAYMENTS(month)=(undergraduaterepayment+postgraduaterepayment-undergraduateinterestpounds-postgraduateinterestpounds)/12;
    if already==0 && NETREPAYMENTS(month)>0 && month>1
        fprintf('You will be repaying less than the interest your loan is accumulating for the first %d years and %d months.\n',fix(month/12),rem(month,12))
        already=1;
    end
    SALARY(month)=salary;
    if month~=1
        TOTALREPAID(month)=TOTALREPAID(month-1)+MONTHLYREPAYMENTS(month);
    else
        TOTALREPAID(month)=MONTHLYREPAYMENTS(month);
    end
end
figure(1)
plot(MONTHS/12,BALANCE/1000)
xlabel('Time after beginning of course (years)')
ylabel('Student debt (£ thousands)')
title('Total student debt')
xlim([0,35])
figure(2)
hold on
under=plot(MONTHS/12,UNDERGRADUATEBALANCE/1000);
post=plot(MONTHS/12,POSTGRADUATEBALANCE/1000);
xlabel('Time after beginning of course (years)')
ylabel('Student debt (£ thousands)')
title('Undergraduate and postgraduate debt')
legend('Undergraduate debt','Postgraduate debt')
hold off
xlim([0,35])
figure(3)
hold on
earnings=plot(MONTHS/12,MONTHLYEARNINGS/1000);
xlabel('Time after beginning of course (years)')
ylabel('Earnings (£ thousands)')
repayments=plot(MONTHS/12,MONTHLYREPAYMENTS/1000);
net=plot(MONTHS/12,(MONTHLYEARNINGS-MONTHLYREPAYMENTS)/1000);
legend('Monthly earnings','Monthly repayments','Net income','location','northwest')
title('Monthly earnings')
hold off
xlim([0,35])
figure(4)
plot(MONTHS/12,TOTALREPAID/1000)
xlabel('Time after beginning of course (years)')
ylabel('Cumulative total (£ thousands)')
title('Cumulative amount repaid')
legend('Running repayment total','Amount originally borrowed')
xlim([0,35])
figure(5)
plot(MONTHS/12,NETREPAYMENTS)
xlabel('Time after beginning of course (years)')
ylabel('Net repayments (£)')
title('Net monthly repayments')
xlim([0,35])
[val,ind]=min(BALANCE);
yearstaken=fix(MONTHS(ind)/12);
monthsextra=rem(MONTHS(ind),12);
if startingpostgraduatebalance==0
    yearstaken=yearstaken-3; % so that time in education does not count towards time spent paying off loan
else
    yearstaken=yearstaken-4;
end
if val<=0 && never==0
    fprintf('It will take %d years and %d months to pay off your entire student loan. Your starting balance is £%.2f and total amount repaid will be £%.2f.\n',yearstaken,monthsextra,startingtotalbalance,sum(MONTHLYREPAYMENTS))
end