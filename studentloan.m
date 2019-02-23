% Plan 2 student loan debt prediction tool, applicable for most graduates since 2012
% Written by Tobie Carman www.linkedin.com/in/tobiecarman
% Relatively simplified model, makes the following assumptions:
% > start work in September after graduation (optimistic)
% > constant yearly pay rise (configurable)
% > RPI remains fixed after leaving university (unlikely but impossible to speculate)
% > repayment threshold continues to rise with inflation - set by government - if they are short of cash they may leave it fixed
% > repayment percentage of salary remains constant (likely)
% > debt wiped after 30 years
% Note all money values are relative to year of starting work, i.e. ignoring inflation over the 30 years

%% Adjustable inputs
courseLength=3; % number of years of undergraduate study
tuition=9000; % annual undergraduate tuition fee loan in £
maintenance=[3575;3610;3469]; % each year of maintenance loan in £
startPostBal=10000; % postgraduate loan amount in £ (change to 0 if not taken)
RPI=0.016; % old rate of inflation (rose from 1.6-3.1% in the last year, may rise further) - this script assumes studying whilst RPI was at the lower value - change to 3.1 if began studying after 2017
salary=28000; % starting annual salary in £
ugThreshold=25000; % repayment salary threshold in £, assumed to rise with inflation (optimistic)
pgThreshold=21000; % postgrad threshold still £21000 :(
payRise=0.01; % annual pay rise above inflation, assumed fixed for simplicity (can be negative)

%% Account for interest accrued during study
studied=1;
undBal=0;
while studied<=courseLength
    undBal=(undBal+tuition+maintenance(studied))*(1+RPI); % total undergraduate loan borrowed in £, has been accumulating interest during study
    studied=studied+1;
end
RPI=0.031; % new RPI

%% Initialise variables
postBal=startPostBal;
startTotBal=undBal+postBal;
totBal=startTotBal;
month=0;
never=0;
already=0;
duration=35*12; % attempt to model over 35 year period after graduation, starting in September of first year in work

%% Pre-allocate arrays for speed
MONTHS=zeros(1,duration);
UNDERGRADUATEBALANCE=zeros(1,duration);
POSTGRADUATEBALANCE=zeros(1,duration);
BALANCE=zeros(1,duration);
MONTHLYEARNINGS=zeros(1,duration);
MONTHLYREPAYMENTS=zeros(1,duration);
SALARY=zeros(1,duration);
TOTALREPAID=zeros(1,duration);
NETREPAYMENTS=zeros(1,duration);

%% Main loop
while month<=duration
    if month==33*12+7 && undBal~=0 % loan gets wiped 30 years after April following graduation
        undBal=0;
        fprintf('You will never repay your entire student loan. Your starting balance is £%.2f, your remaining balance will be £%.2f, total amount repaid will be £%.2f.\n',startTotBal,totBal,sum(MONTHLYREPAYMENTS))
        never=1;
    elseif month==34*12+7
        postBal=0;
    end
    if salary-ugThreshold>0
        extra=(salary-ugThreshold)*0.0000015; % extra interest paid due to salary
        if extra>0.03 % extra interest capped at 3%
            extra=0.03;
        end
        undRepay=(salary-ugThreshold)*0.09; % amount paid back per year towards undergraduate debt
        postRepay=(salary-pgThreshold)*0.06; % amount paid back per year towards postgraduate debt
    elseif salary-pgThreshold>0
        undRepay=0;
        postRepay=(salary-pgThreshold)*0.06;
    else
        extra=0;
        undRepay=0;
        postRepay=0;
    end
    if month<7
        undRepay = 0; % won't start paying back until April after graduation
    end
    if month<19
        postRepay = 0; % won't start paying back until April after graduation
    end
    if undBal>undRepay/12
        undBal = undBal-undRepay/12; % monthly repayments
    elseif undBal>0 % Avoids overpayment on final instalment
        undRepay = undBal*12;
        undBal = 0;
    else
        undRepay = 0;
    end
    if postBal>postRepay/12
        postBal = postBal-postRepay/12;
    elseif postBal>0
        postRepay = postBal*12;
        postBal = 0;
        fprintf('You will repay your postgraduate loan after %d years and %d months.\n',fix(month/12),rem(month,12))
    else
        postRepay = 0;
    end
    undIntPc=RPI+extra; % interest percentage
    postIntPc=RPI+0.03; % extra interest flat 3% for postgraduate loan
    if mod(month,12)==0
        salary=salary*(1+RPI+payRise); % assuming salary rises every year by inflation + x%
        ugThreshold=ugThreshold*(1+RPI); % assuming repayment threshold rises every year with inflation
        pgThreshold=pgThreshold*(1+RPI); % this one seems to be fixed for the moment but who knows
    end
    undIntPnd=undIntPc*undBal; % how much undergraduate balance will rise by due to interest in £
    postIntPnd=postIntPc*postBal; % how much postgraduate balance will rise by due to interest in £
    undBal=undBal+undIntPnd/12; % accounting for interest after repayments i.e. best case scenario
    postBal=postBal+postIntPnd/12;
    totBal=undBal+postBal;
    month=month+1;
    MONTHS(month)=month;
    UNDERGRADUATEBALANCE(month)=undBal;
    POSTGRADUATEBALANCE(month)=postBal;
    BALANCE(month)=totBal;
    MONTHLYEARNINGS(month)=salary/12;
    MONTHLYREPAYMENTS(month)=(undRepay+postRepay)/12;
    NETREPAYMENTS(month)=(undRepay+postRepay-undIntPnd-postIntPnd)/12;
    if already==0 && NETREPAYMENTS(month)>0 && month>1
        fprintf('You will be repaying less than the interest your loans are accumulating for the first %d years and %d months.\n',fix(month/12),rem(month,12))
        already=1;
    end
    SALARY(month)=salary;
    if month~=1
        TOTALREPAID(month)=TOTALREPAID(month-1)+MONTHLYREPAYMENTS(month);
    else
        TOTALREPAID(month)=MONTHLYREPAYMENTS(month);
    end
end

%% Output results
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
yearsTaken=fix(MONTHS(ind)/12);
monthsExtra=rem(MONTHS(ind),12);
if startPostBal==0
    yearsTaken=yearsTaken-3; % so that time in education does not count towards time spent paying off loan
else
    yearsTaken=yearsTaken-4;
end
if val<=0 && never==0
    fprintf('It will take %d years and %d months to pay off your entire student loan. Your starting balance is £%.2f and total amount repaid will be £%.2f.\n',yearsTaken,monthsExtra,startTotBal,sum(MONTHLYREPAYMENTS))
end
