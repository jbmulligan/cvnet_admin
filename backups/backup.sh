#!/bin/sh
# Local host MongoDB dump
# Note: this script sources from $HOME/.mongodumprc two parameters:
# BACKUP_DIR - backup directory, e.g. $HOME/db_backups/localhost
# URI - mongodump --uri argument, e.g. mongodb://user:password@localhost/

# Set default parameters
keep_hourly=10
keep_daily=7
keep_weekly=4
keep_monthly=4
daily_hour=3
weekly_day=6
monthly_day=1

# Parse command line options
parse_opts() {
    USAGE="Usage: $0 [-h keep_hourly] [-d keep_daily] [-w keep_weekly] [-m keep_monthly]"
    while getopts :h:d:w:m: o
    do
        case $o in
            h)  keep_hourly=$OPTARG;;
            d)  keep_daily=$OPTARG;;
            w)  keep_weekly=$OPTARG;;
            m)  keep_monthly=$OPTARG;;
            *)  echo $USAGE; exit 1
        esac
    done
}

# Set archive path
set_archive_path() {
    this_hour=`date "+%H"`
    this_weekday=`date "+%u"`
    this_monthday=`date "+%d"`
    time_stamp=`date "+%Y%m%d-%H%M"`
    # Select archive subdirectory
    if [ $keep_hourly -gt 0 ]
    then
        archive_dir="$BACKUP_DIR"/hourly
    fi
    if [ $keep_daily -gt 0 -a $this_hour -eq $daily_hour ]
    then
        archive_dir="$BACKUP_DIR"/daily
    fi
    if [ $keep_weekly -gt 0 -a $this_weekday -eq $weekly_day -a $this_hour -eq $daily_hour ]
    then
        archive_dir="$BACKUP_DIR"/weekly
    fi
    if [ $keep_monthly -gt 0 -a $this_monthday -eq $monthly_day -a $this_hour -eq $daily_hour ]
    then
        archive_dir="$BACKUP_DIR"/monthly
    fi
    # Create directory if it doesn't exist
    [ -d "$archive_dir" ] || mkdir "$archive_dir"
    # Set full path
    archive="$archive_dir"/${time_stamp}.gz
}

# Delete old database dumps
del_old_dumps() {
    for subdir in hourly daily weekly monthly
    do
        case $subdir in
            hourly)  nmax=$keep_hourly;;
            daily)   nmax=$keep_daily;;
            weekly)  nmax=$keep_weekly;;
            monthly) nmax=$keep_monthly;;
        esac
        dump_dir="$BACKUP_DIR"/$subdir
        [ -d "$dump_dir" ] || continue
        [ $nmax -ge 0 ] || continue
        (   # Run the following code in a sub-shell
            cd "$dump_dir"
            n=`ls -t | wc -l`
            while [ $n -gt $nmax ]
            do
                rm -r `ls -t | tail -1`
                n=`ls -t | wc -l`
            done
        )
    done
}

# Update link to latest dump (use after successful dump)
set_latest_link() {
    [ -h "$BACKUP_DIR"/latest ] && rm "$BACKUP_DIR"/latest
    b=`basename "$archive"`
    d=`dirname "$archive"`
    ln -s `basename "$d"`/$b "$BACKUP_DIR"/latest
}

# Main script
set -e
umask 0077
. $HOME/.mongodumprc
parse_opts $*
set_archive_path
mongodump --uri="$URI" --gzip --archive="$archive" && set_latest_link
del_old_dumps

