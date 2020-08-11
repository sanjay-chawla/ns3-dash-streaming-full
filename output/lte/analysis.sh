#!/bin/bash 

CONTENT="~/home/sanjay/git/content"
REQUESTS="~/home/sanjay/git/content/requests"
RESULTS="~/home/sanjay/git/content/results"
DASH_REPORT="report.csv"

QUANTILES=(0 5 10 25 50 75 90 95 100)

if [ -d $RESULTS ];
then
        rm -rf $RESULTS
        mkdir $RESULTS
else
        mkdir $RESULTS
fi

min_rid=0
if [ "$#" -eq 1 ];
then
	min_rid=1
fi

printf "Node,StartUpDelay,AvgDownloadRate,StdDownloadRate,AvgBufferLevel,StdBufferLevel,StallEvents,RebufferingRatio,StallLabel,TotalStallingTime,AvgTimeStallingEvents,AvgVideoBitRate,AvgVideoQualityVariation,RSDVideoBitRate,AvgDownloadBitRate\n" >> $RESULTS/data

#Read requests
#source, server, startsAt, stopsAt, videoId, screenWidth, screenHeight
#UserId,StartsAt,StopsAt,VideoId,LinkCapacity,ScreenWidth,ScreenHeight
rid=0
while IFS='' read -r line || [[ -n "$line" ]]; do
    printf "${line}\n";
    if [[ !($line =~ ^#) ]] && (( $rid > $min_rid ));
    then
	# Retreive request data 
	fields=($(printf "%s" "$line"|cut -d',' --output-delimiter=' ' -f1-))
	
        source=${fields[0]}
	#server=${fields[2]}
	startsAt=${fields[1]}
	stopsAt=${fields[2]}
	videoId=${fields[3]}
	sWidth=${fields[5]}
	sHeight=${fields[6]}
	printf "${source} ${videoId} ${sWidth}:${sHeight}\n"
	RequestDuration=$(echo "a" | awk '{printf stopsAt-startsAt}' stopsAt=$stopsAt startsAt=$startsAt)
	#####################################
	# DASH Player statistics
	#####################################
	# Time Node UserId  SegmentNumber SegmentRepID SegmentExperiencedBitrate(bit/s) BufferLevel(s)  StallingTime(msec) 
	# downloading speed (avg, dev), stall events, stall duration (avg, std), video bitrate (avg, std), quality variation (avg, std)
	videoId=$(($videoId+1))
        cat $CONTENT/representations/netflix_vid$videoId.csv | awk '(NR>4){print $0}' | sed 's/,/ /g' | awk '{print $1 " " $4}' > $RESULTS/representations	
	StartUpDelay=$(cat $DASH_REPORT | awk 'BEGIN{s=0};{if($2==source){if(ok!=1){s=$8;ok=1}}};END{printf s};' source=$source)
	AvgDownloadRate=$(cat $DASH_REPORT | awk '($2==source){s=s+$6;c++};END{if(c>0){printf s/c}else{printf 0}}' source=$source)
	StdDownloadRate=$(cat $DASH_REPORT | awk '($2==source){s=s+($6-AvgDownloadRate)^2;c++};END{if(c>0){printf sqrt(s/c)}else{printf 0}}' source=$source AvgDownloadRate=$AvgDownloadRate)
        AvgBufferLevel=$(cat $DASH_REPORT | awk '($2==source){s=s+$7;c++};END{if(c>0){printf s/c}else{printf 0}}' source=$source)
        StdBufferLevel=$(cat $DASH_REPORT | awk '($2==source){s=s+($7-AvgBufferLevel)^2;c++};END{if(c>0){printf sqrt(s/c)}else{printf 0}}' source=$source AvgBufferLevel=$AvgBufferLevel)
        StallEvents=$(cat $DASH_REPORT | awk 'BEGIN{c=0};{if($2==source){if(ok==1){if($8>0){c++}};ok=1}};END{printf c}' source=$source)
        TotalStallingTime=$(cat $DASH_REPORT | awk 'BEGIN{s=0};{if($2==source){if(ok==1){s=s+$8};ok=1}};END{printf s}' source=$source)
	RebufferingRatio=$(echo "a" | awk '{printf TotalStallingTime/1000/RequestDuration}' TotalStallingTime=$TotalStallingTime RequestDuration=$RequestDuration)
	StallLabel=$(echo "a" | awk '{m="NA";r=RebufferingRatio;if(r==0){m="NoStalling"}else if(r<=0.1){m="MildStalling"}else{m="SevereStalling"};printf m}' RebufferingRatio=$RebufferingRatio)
        AvgTimeStallingEvents=$(cat $DASH_REPORT | awk '($2==source){print $0}' | awk '{if(NR>1){s=s+$8;c++}};END{if(c>0){printf s/c}else{printf 0}}' source=$source)
	AvgVideoBitRate=$(awk '{if(!(FILENAME~/report/)){rep[$1]=$2}else{if($2==source){s=s+rep[$5];c++}}};END{if(c>0){printf s/c}else{printf 0}}' source=$source $RESULTS/representations $DASH_REPORT)
	RSDVideoBitRate=$(awk '{if(!(FILENAME~/report/)){rep[$1]=$2}else{if($2==source){s=s+(AvgVideoBitRate-rep[$5])^2;c++}}};END{if(c>0){printf sqrt(s/c)/AvgVideoBitRate*100}else{printf 0}}' AvgVideoBitRate=$AvgVideoBitRate AvgVideoBitRate=$AvgVideoBitRate source=$source $RESULTS/representations $DASH_REPORT)
	AvgVideoQualityVariation=$(awk 'function abs(x){return ((x < 0.0) ? -x : x)};BEGIN{br=0};{if(!(FILENAME~/report/)){rep[$1]=$2}else{if($2==source){if(br!=0){s=s+abs(br-rep[$5]);c++};br=rep[$5]}}};END{if(c>0){printf s/c}else {printf 0}}' source=$source $RESULTS/representations $DASH_REPORT)
	AvgDownloadBitRate=$(awk '{if($2==source){s=s+$6;c++}};END{if(c>0){printf s/c}else{printf 0}}' source=$source $DASH_REPORT)

	printf "$source,$StartUpDelay,$AvgDownloadRate,$StdDownloadRate,$AvgBufferLevel,$StdBufferLevel,$StallEvents,$RebufferingRatio,$StallLabel,$TotalStallingTime,$AvgTimeStallingEvents,$AvgVideoBitRate,$AvgVideoQualityVariation,$RSDVideoBitRate,$AvgDownloadBitRate\n" >> $RESULTS/data
    elif [[ !($line =~ ^#) ]];
    then
        # Retreive request data
        fields=($(printf "%s" "$line"|cut -d',' --output-delimiter=' ' -f1-))
        #source=${fields[1]}
        #server=${fields[2]}
        #startsAt=${fields[3]}
        #stopsAt=${fields[4]}
        #videoId=${fields[5]}
        #sWidth=${fields[6]}
        #sHeight=${fields[7]}
   
        
    fi
    rid=$((rid+1))
done < $REQUESTS/demo_req.csv









