#!/usr/bin/env php
<?php

require_once("../inc/util_ops.inc");

// use $sub_projects defined in project/project.inc
// (this speeds up the assignment of badges)
// "total" is a special sub project and should only be defined here
//
global $sub_projects;
$badges_sub_projects = $sub_projects;
$badges_sub_projects[] = array("name" => "project total", "short_name" => "total");

// thresholds for the various badges
// currently we use the same threshold for all badges (total and subproject)
// minimum total credits for each level and corresponding names
//
$badge_levels = array(
    10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 20000000
);
$badge_level_names = array(
    "10K", "50K", "100K", "500K", "1M", "5M", "10M", "20M"
);
$badge_images = array(
    "c10k", "c50k", "c100k", "c500k", "c1m", "c5m", "c10m", "c20m"
);

// consistency checks
//
$num_levels = count($badge_levels);
if ($num_levels <> count($badge_level_names)) {
    die("number of badge_levels is not equal to number of badge_level_names");
}
if ($num_levels <> count($badge_images)) {
    die("number of badge_levels is not equal to number of badge_images");
}

// get the record for a badge
// badge_name_prefix should be user or team
//
function get_badges($badge_name_prefix, $badge_level_names, $badge_images, $sub_project) {
    $badges = array();
    $limit = count($badge_level_names);
    for ($i=0; $i < $limit; $i++) {
        $badges[$i] = get_badge($badge_name_prefix."_".$badge_images[$i], "$badge_level_names[$i] in total credit", "$badge_images[$i].png");
    }
    return $badges;
}

// decide which project total badge to assign, if any.
// Unassign other badges.
//
function assign_tot_badge($is_user, $item, $levels, $badges) {
    // count from highest to lowest level, so the user get's assigned the
    // highest possible level and the lower levels get removed
    //
    for ($i=count($levels)-1; $i>=0; $i--) {
        if ($item->total_credit >= $levels[$i]) {
            assign_badge($is_user, $item, $badges[$i]);
            unassign_badges($is_user, $item, $badges, $i);
            return;
        }
    }
    // no level could be assigned so remove them all
    //
    unassign_badges($is_user, $item, $badges, -1);
}

// decide which subproject badge to assign, if any.
// Unassign other badges.
//
function assign_sub_badge($is_user, $item, $levels, $badges, $where_clause) {
    if ($is_user) {
        $sub_total = BoincCreditUser::sum('total', "where userid=".$item->id." and ($where_clause)");
    } else {
        $sub_total = BoincCreditTeam::sum('total', "where teamid=".$item->id." and ($where_clause)");
    }
    // count from highest to lowest level, so the user get's assigned the
    // highest possible level and the lower levels get removed
    //
    for ($i=count($levels)-1; $i>=0; $i--) {
        if ($sub_total >= $levels[$i]) {
            assign_badge($is_user, $item, $badges[$i]);
            unassign_badges($is_user, $item, $badges, $i);
            return;
        }
    }
    // no level could be assigned so remove them all
    //
    unassign_badges($is_user, $item, $badges, -1);
}


// Scan through all the users/teams, 1000 at a time,
// and assign/unassign the badges (total and subproject)
//
function assign_all_badges(
    $is_user, $badge_levels, $badge_level_names, $badge_images,
    $subprojects_list
) {
    $kind = $is_user?"user":"team";

    // get badges for all subprojects including total
    //
    foreach ($subprojects_list as $sp) {
        $badges[$sp["short_name"]] = get_badges($kind, $badge_level_names, $badge_images, $sp);
    }

    $n = 0;
    $maxid = $is_user?BoincUser::max("id"):BoincTeam::max("id");
    while ($n <= $maxid) {
        $m = $n + 1000;
        if ($is_user) {
            $items = BoincUser::enum_fields("id, total_credit", "id>=$n and id<$m and total_credit>0");
        } else {
            $items = BoincTeam::enum_fields("id, total_credit", "id>=$n and id<$m and total_credit>0");
        }
        // for every user/team
        //
        foreach ($items as $item) {
            // for every subproject (incl. total)
            //
            foreach ($subprojects_list as $sp) {
                if ($sp["short_name"] == "total") {
                    assign_tot_badge($is_user, $item, $badge_levels, $badges["total"]);
                } else {
                    // appids come from project/project.inc
                    $where_clause = "appid in (". implode(',', $sp["appids"]) .")";
                    assign_sub_badge(
                        $is_user, $item, $badge_levels, $badges[$sp["short_name"]],
                        $where_clause
                    );
                }
            }
        }
        $n = $m;
    }
}

echo "Starting: ", time_str(time()), "\n";

// one pass through DB for users
assign_all_badges(
    true, $badge_levels, $badge_level_names, $badge_images,
    $badges_sub_projects
);

echo "Finished: ", time_str(time()), "\n";

?>