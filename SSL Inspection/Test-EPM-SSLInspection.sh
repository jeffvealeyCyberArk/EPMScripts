#!/bin/bash
# Test-EPM-SSLInspection.sh - Idira EPM SSL Inspection Tester for macOS/Linux

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

KNOWN_ISSUERS="Cloudflare|Google Trust Services|Amazon|DigiCert|GlobalSign|Starfield"

# Results arrays for CSV export
declare -a CSV_RESULTS
CSV_COUNT=0

# Server lists by region (updated from EPM Servers List.csv)
NA_SERVERS="NA109 NA110 NA111 NA112 NA113 NA114 NA115 NA116 NA117 NA118 NA119 NA120 NA121 NA122 NA123 NA128 NA132 NA133 NA134 NA135 NA136 NA137 NA148 NA156 NA157 NA159 NA160 NA161 NA163 NA168 NA170 NA171 NA172 NA173 NA177 NA180 NA181 NA182 NA183 NA184 NA186 NA188 NA190 NA193 NA194 NA197 NA198 NA199 NA202 NA203 NA204 NA206 NA207 NA220 NA221 NA222 NA223 NA224 NA225 NA226 NA227 NA228 NA229 NA230 NA234 NA235 NA236 NA237 NA241 NA242 NA243"
EU_SERVERS="SVC8 EU124 EU131 EU140 EU145 EU155 EU162 EU164 EU165 EU166 EU167 EU169 EU187 EU191 EU192 EU200 EU208 EU219 EU232 EU239 EU240 EU247 EU248"
AU_SERVERS="AU126 AU138 AU151 AU185"
BR_SERVERS="BR233"
CA_SERVERS="CA127 CA139 CA150 CA176 CA211"
CH_SERVERS="CH195"
IL_SERVERS="IL231"
IN_SERVERS="IN129 IN141 IN146 IN152 IN175"
IT_SERVERS="IT178 IT179 IT216 IT238"
JP_SERVERS="JP130 JP142 JP153"
SG_SERVERS="SG144 SG147 SG154 SG201"
UK_SERVERS="UK125 UK143 UK149 UK174 UK196 UK210"
FED_SERVERS="NA01 NA02 NA03 NA04 NA05 NA06"

# Check for curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${NC}"
    exit 1
fi

clear_results() {
    CSV_RESULTS=()
    CSV_COUNT=0
}

test_url() {
    local url="$1"
    local url_type="$2"
    
    echo -e "  Testing: $url"
    
    local cert_info
    cert_info=$(curl -vvI --insecure --connect-timeout 15 --max-time 20 "$url" 2>&1)
    
    local subject=$(echo "$cert_info" | grep -i "subject:" | head -1 | sed 's/.*subject: //')
    local issuer=$(echo "$cert_info" | grep -i "issuer:" | head -1 | sed 's/.*issuer: //')
    local expire=$(echo "$cert_info" | grep -i "expire date:" | head -1 | sed 's/.*expire date: //')
    local ssl_status=""
    local error=""
    
    if [ -z "$subject" ] && [ -z "$issuer" ]; then
        echo -e "    ${RED}ERROR: Could not retrieve certificate${NC}"
        error="Could not retrieve certificate"
        ssl_status="Unknown"
        CSV_RESULTS[$CSV_COUNT]="\"$url\",\"$url_type\",\"\",\"\",\"\",\"Error\",\"$ssl_status\",\"$error\""
        ((CSV_COUNT++))
        echo ""
        return
    fi
    
    echo -e "    Type:    $url_type"
    echo -e "    Subject: $subject"
    echo -e "    Issuer:  $issuer"
    echo -e "    Expires: $expire"
    
    if echo "$issuer" | grep -qiE "$KNOWN_ISSUERS"; then
        echo -e "    SSL Inspection: ${GREEN}Not Detected${NC}"
        ssl_status="Not Detected"
    else
        echo -e "    SSL Inspection: ${RED}LIKELY DETECTED${NC}"
        echo -e "    ${YELLOW}WARNING: Issuer does not match expected Idira/Amazon/Cloudflare CA${NC}"
        ssl_status="LIKELY DETECTED"
    fi
    
    subject=$(echo "$subject" | sed 's/"/""/g')
    issuer=$(echo "$issuer" | sed 's/"/""/g')
    
    CSV_RESULTS[$CSV_COUNT]="\"$url\",\"$url_type\",\"$subject\",\"$issuer\",\"$expire\",\"Valid\",\"$ssl_status\",\"\""
    ((CSV_COUNT++))
    
    echo ""
}

export_to_csv() {
    local filename="$1"
    
    echo "URL,URLType,Subject,Issuer,Expires,Status,SSLInspection,Error" > "$filename"
    
    for ((i=0; i<CSV_COUNT; i++)); do
        echo "${CSV_RESULTS[$i]}" >> "$filename"
    done
    
    echo -e "  ${GREEN}Results exported to: $filename${NC}"
}

show_menu() {
    echo -e "${CYAN}"
    echo "  Idira EPM SSL Inspection Tester"
    echo -e "${NC}"
    echo "  Select region:"
    echo "   1) AU - Australia (4 servers)"
    echo "   2) BR - Brazil (1 server)"
    echo "   3) CA - Canada (5 servers)"
    echo "   4) CH - Switzerland (1 server)"
    echo "   5) EU - Germany/EU (23 servers)"
    echo "   6) IL - Israel (1 server)"
    echo "   7) IN - India (5 servers)"
    echo "   8) IT - Italy (4 servers)"
    echo "   9) JP - Japan (3 servers)"
    echo "  10) SG - Singapore (4 servers)"
    echo "  11) UK - United Kingdom (6 servers)"
    echo "  12) NA - USA (70 servers)"
    echo "  13) FED - US FedRAMP (6 servers)"
    echo ""
    echo "  Or enter a specific server (e.g., NA123, EU140, NA01)"
    echo ""
}

get_region_info() {
    local r="$1"
    case "$r" in
        AU) echo "Australia|$AU_SERVERS|https://files-au.epm.cyberark.com|https://agents-au.epm.cyberark.com" ;;
        BR) echo "Brazil|$BR_SERVERS|https://files-br.epm.cyberark.com|https://agents-br.epm.cyberark.com" ;;
        CA) echo "Canada|$CA_SERVERS|https://files-ca.epm.cyberark.com|https://agents-ca.epm.cyberark.com" ;;
        CH) echo "Switzerland|$CH_SERVERS|https://files-ch.epm.cyberark.com|https://agents-ch.epm.cyberark.com" ;;
        EU) echo "Germany/EU|$EU_SERVERS|https://files-eu.epm.cyberark.com|https://agents-eu.epm.cyberark.com" ;;
        IL) echo "Israel|$IL_SERVERS|https://files-il.epm.cyberark.com|https://agents-il.epm.cyberark.com" ;;
        IN) echo "India|$IN_SERVERS|https://files-in.epm.cyberark.com|https://agents-in.epm.cyberark.com" ;;
        IT) echo "Italy|$IT_SERVERS|https://files-it.epm.cyberark.com|https://agents-it.epm.cyberark.com" ;;
        JP) echo "Japan|$JP_SERVERS|https://files-jp.epm.cyberark.com|https://agents-jp.epm.cyberark.com" ;;
        SG) echo "Singapore|$SG_SERVERS|https://files-sg.epm.cyberark.com|https://agents-sg.epm.cyberark.com" ;;
        UK) echo "United Kingdom|$UK_SERVERS|https://files-uk.epm.cyberark.com|https://agents-uk.epm.cyberark.com" ;;
        NA) echo "USA|$NA_SERVERS|https://files-na.epm.cyberark.com|https://agents-na.epm.cyberark.com" ;;
        FED) echo "US FedRAMP|$FED_SERVERS|https://files.epm.cyberarkgov.cloud|https://apro78z9ol93v-ats.iot.us-gov-west-1.amazonaws.com" ;;
        *) echo "" ;;
    esac
}

get_region_from_server() {
    local s=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    if [[ "$s" =~ ^NA0[1-6]$ ]]; then echo "FED"
    elif [[ "$s" =~ ^(NA|SVC)[0-9]+$ ]]; then echo "NA"
    elif [[ "$s" =~ ^EU[0-9]+$ ]]; then echo "EU"
    elif [[ "$s" =~ ^AU[0-9]+$ ]]; then echo "AU"
    elif [[ "$s" =~ ^BR[0-9]+$ ]]; then echo "BR"
    elif [[ "$s" =~ ^CA[0-9]+$ ]]; then echo "CA"
    elif [[ "$s" =~ ^CH[0-9]+$ ]]; then echo "CH"
    elif [[ "$s" =~ ^IL[0-9]+$ ]]; then echo "IL"
    elif [[ "$s" =~ ^IN[0-9]+$ ]]; then echo "IN"
    elif [[ "$s" =~ ^IT[0-9]+$ ]]; then echo "IT"
    elif [[ "$s" =~ ^JP[0-9]+$ ]]; then echo "JP"
    elif [[ "$s" =~ ^SG[0-9]+$ ]]; then echo "SG"
    elif [[ "$s" =~ ^UK[0-9]+$ ]]; then echo "UK"
    fi
}

get_tenant_url() {
    local server="$1"
    local region="$2"
    
    if [ "$region" = "FED" ]; then
        echo "https://$server.epm.cyberarkgov.cloud"
    else
        echo "https://$server.epm.cyberark.com"
    fi
}

test_region() {
    local region="$1"
    local name="$2"
    local servers="$3"
    local s3="$4"
    local agent="$5"
    
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN}  Testing Region: $name ($region)${NC}"
    echo -e "${CYAN}================================================${NC}\n"
    
    echo -e "${YELLOW}[Tenant URLs]${NC}"
    if [ -n "$servers" ]; then
        for srv in $servers; do
            local url=$(get_tenant_url "$srv" "$region")
            test_url "$url" "Tenant"
        done
    fi
    
    echo -e "${YELLOW}[S3/Download URLs]${NC}"
    test_url "$s3" "S3/Downloads"
    
    echo -e "${YELLOW}[Agent URLs]${NC}"
    test_url "$agent" "Agent"
}

display_summary() {
    local inspection_count=0
    local error_count=0
    
    for ((i=0; i<CSV_COUNT; i++)); do
        if echo "${CSV_RESULTS[$i]}" | grep -q "LIKELY DETECTED"; then
            ((inspection_count++))
        fi
        if echo "${CSV_RESULTS[$i]}" | grep -q "\"Error\""; then
            ((error_count++))
        fi
    done
    
    echo -e "\n${CYAN}[SUMMARY]${NC}"
    echo -e "Total URLs tested:     $CSV_COUNT"
    if [ $inspection_count -gt 0 ]; then
        echo -e "SSL Inspection likely: ${RED}$inspection_count${NC}"
    else
        echo -e "SSL Inspection likely: ${GREEN}0${NC}"
    fi
    echo -e "Errors:                $error_count"
    
    if [ $inspection_count -gt 0 ]; then
        echo -e "\n${YELLOW}[ACTION REQUIRED]${NC}"
        echo -e "${YELLOW}SSL inspection was detected. Please configure your proxy/firewall to bypass SSL inspection.${NC}"
        echo -e "Reference: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm"
    fi
}

# Main
while true; do
    clear_results
    show_menu
    read -p "  Enter selection: " input
    input=$(echo "$input" | tr '[:lower:]' '[:upper:]')
    
    region=""
    server=""
    result_label=""
    
    case "$input" in
        1|AU) region="AU" ;;
        2|BR) region="BR" ;;
        3|CA) region="CA" ;;
        4|CH) region="CH" ;;
        5|EU) region="EU" ;;
        6|IL) region="IL" ;;
        7|IN) region="IN" ;;
        8|IT) region="IT" ;;
        9|JP) region="JP" ;;
        10|SG) region="SG" ;;
        11|UK) region="UK" ;;
        12|NA) region="NA" ;;
        13|FED) region="FED" ;;
        *)
            if [[ "$input" =~ ^NA0[1-6]$ ]]; then
                server="$input"
                region="FED"
            elif [[ "$input" =~ ^(NA|EU|AU|BR|CA|CH|IL|IN|IT|JP|SG|UK|SVC)[0-9]+$ ]]; then
                server="$input"
                region=$(get_region_from_server "$server")
            else
                echo -e "${RED}Invalid selection${NC}"
                continue
            fi
            ;;
    esac
    
    data=$(get_region_info "$region")
    if [ -z "$data" ]; then
        echo -e "${RED}Invalid region${NC}"
        continue
    fi
    
    IFS='|' read -r name servers s3 agent <<< "$data"
    
    if [ -n "$server" ]; then
        result_label="$server"
        echo -e "\n${CYAN}Testing Server: $server${NC}\n"
        echo -e "${YELLOW}[Tenant URL - Specific Server]${NC}"
        local url=$(get_tenant_url "$server" "$region")
        test_url "$url" "Tenant (Specific)"
        
        echo -e "${YELLOW}[S3/Download URLs]${NC}"
        test_url "$s3" "S3/Downloads"
        
        echo -e "${YELLOW}[Agent URLs]${NC}"
        test_url "$agent" "Agent"
    else
        result_label="$region"
        test_region "$region" "$name" "$servers" "$s3" "$agent"
    fi
    
    display_summary
    
    echo ""
    read -p "  Export results to CSV? (Y/N): " export_choice
    if [[ "$export_choice" =~ ^[Yy]$ ]]; then
        timestamp=$(date "+%Y%m%d_%H%M%S")
        export_path="EPM_SSL_Results_${result_label}_${timestamp}.csv"
        export_to_csv "$export_path"
    fi
    
    echo ""
    read -p "  Test another? (Y/N): " again
    if [[ ! "$again" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${CYAN}Thank you for using the Idira EPM SSL Inspection Tester!${NC}"
        echo -e "  Reference: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm\n"
        break
    fi
    echo ""
done