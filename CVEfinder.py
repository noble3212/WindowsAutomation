import os
import requests
import json
import subprocess

# Function to get installed software versions (Windows example)
def get_installed_software():
    installed_programs = []
    result = subprocess.run(['wmic', 'product', 'get', 'name,version'], stdout=subprocess.PIPE, text=True)
    programs = result.stdout.split('\n')[1:]
    
    for program in programs:
        if program.strip():
            name, version = program.strip().split('  ', 1)
            installed_programs.append((name, version))
    return installed_programs

# Function to check CVE database for known vulnerabilities (using public CVE API)
def check_cve_for_programs(installed_programs):
    cve_base_url = "https://cve.circl.lu/api/cvefor"
    
    for name, version in installed_programs:
        cve_url = f"{cve_base_url}/{name}/{version}"
        response = requests.get(cve_url)
        if response.status_code == 200:
            cve_data = response.json()
            if cve_data['results']:
                print(f"Vulnerabilities found for {name} {version}:")
                for cve in cve_data['results']:
                    print(f" - CVE: {cve['id']}, Description: {cve['description']}")
            else:
                print(f"No known vulnerabilities found for {name} {version}.")
        else:
            print(f"Failed to retrieve CVE data for {name} {version}.")

# Main function
def main():
    installed_programs = get_installed_software()
    if installed_programs:
        check_cve_for_programs(installed_programs)
    else:
        print("No installed programs found.")

if __name__ == "__main__":
    main()
