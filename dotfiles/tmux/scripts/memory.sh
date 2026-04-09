#!/usr/bin/env bash

threshold=${1:-60}

case "$(uname)" in
Darwin)
	total_bytes=$(sysctl -n hw.memsize)
	percentage_total_used=$(vm_stat | awk '
	NR==1 {
		match($0, /([0-9]+)/, arr);
		page_size = arr[1]
	}
	/Pages (active|wired down)/ {
		match($0, / +([0-9]+)/, arr);
		used_pages += arr[1];
	}
	END {
		total_bytes = '"$total_bytes"'
		total_pages = (total_bytes / page_size)
		gb = 1024 * 1024 * 1024;
		percentage = (used_pages / total_pages) * 100;
		total = int(total_bytes / gb + 0.5)
		used = (used_pages * page_size) / gb
		printf("%.0f,%dG,%.1fG", percentage, total, used)
	}')
	;;
Linux)
	percentage_total_used=$(free -h --giga | awk '/Mem/ { print int(($3/$2)*100) "," $2 "," $3 }')
	;;
*)
	# Unknown OS
	return 1
	;;
esac

IFS=',' read -r percentage total used <<<"$percentage_total_used"

if ((percentage < threshold)); then
	exit
fi

left_sep_char="#{E:@catppuccin_status_left_separator}"
right_sep_char="#{E:@catppuccin_status_right_separator}"
icon="󰍛"

mem_high_fg="#{E:@thm_crust}"
base_fg="#{E:@thm_fg}"

mem_high_bg="#{E:@thm_red}"
base_bg="#{E:@catppuccin_status_module_text_bg}"

mem_high_style="fg=$mem_high_fg bg=$mem_high_bg"
base_style="fg=$base_fg bg=$base_bg"

mem_high_sep_style="fg=$mem_high_bg bg=default"
sep_style="fg=$base_bg bg=default"

left_sep="#[$mem_high_sep_style]$left_sep_char#[$mem_high_style]$icon #[default]"
right_sep="#[$sep_style]$right_sep_char#[default]"
echo "$left_sep#[$mem_high_style]$percentage% #[$base_style] $used/$total$right_sep"
