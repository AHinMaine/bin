import re
import sys
import json
import requests

def ddump(dumpname,dumpvar):
    print('========================')
    print(dumpname)
    print(dumpvar)
    #pprint.pprint(dumpvar)
    
    
def fix_commas(input_string):
    #
    # Strip commas, but just replace with spaces in case the input is foo,bar,baz
    #
    if ',' in input_string:
        modified_string = input_string.replace(',', ' ')
        return modified_string
    else:
        return input_string


def parse_year_range_string(range_string):
    #
    # Parses the weird temporalDescription string in FS output
    #
    match = re.match(r"^\+(\d{4})/\+(\d{4})$", range_string)
    if match:
        start_year_str = match.group(1)
        end_year_str = match.group(2)
        return int(start_year_str), int(end_year_str)

    match = re.match(r"^\+(\d{4})/$", range_string)
    if match:
        start_year_str = match.group(1)
        return int(start_year_str), '0000'

    return None


def parse_places(json_data):

    data = json.loads(json_data)

    adata = { 'items': [] }

    for entry in data['entries']:

        if 'content' in entry and 'gedcomx' in entry['content'] and 'places' in entry['content']['gedcomx']:

            for place in entry['content']['gedcomx']['places']:

                output_string = ''

                adata_item_title = ''
                adata_item_subtitle = ''
                adata_item_arg = ''
                
                start_year = '0000'
                end_year = '0000'
                
                if 'temporalDescription' in place and 'formal' in place['temporalDescription']:
                    #print(place['temporalDescription']['formal'])

                    years = parse_year_range_string(place['temporalDescription']['formal'])
                    if years:
                        start_year, end_year = years

                # Skip the items with no span of years, not really sure what the 
                # point of them is anyway.
                if str(start_year) == '0000' and str(end_year) == '0000':
                    continue
                    
                adata_item_title = '-'.join([str(start_year), str(end_year)])

                if 'display' in place and 'fullName' in place['display']:
                    #print(place['display']['fullName'])
                    adata_item_title = ' '.join([adata_item_title, place['display']['fullName']])
                    adata_item_arg = place['display']['fullName']
                    adata_item_subtitle = place['display']['fullName']
                
                if len(adata_item_arg) > 0 and len(adata_item_title) > 0:
                    adata['items'].append({
                        'title': adata_item_title,
                        'subtitle': adata_item_subtitle,
                        'arg': adata_item_arg
                    })

    return adata


def main():

    if len(sys.argv) < 2:
        print('Error: No command-line arguments provided.')
        sys.exit(1)

    arguments = sys.argv[1:]

    new_string = fix_commas(arguments)

    # TODO
    # Make this smarter
    combined_string = '+'.join(new_string)


    url = 'https://api.familysearch.org/platform/places/search'

    headers = {
        'Accept': 'application/x-gedcomx-atom+json'
    }
    
    name_query = 'name:' + combined_string

    params = {
        'q': name_query
    }

    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
    
        # Process the response data
        ##_## print(response.text)  # Print the raw response content
        parsed_places = parse_places(response.text)
        
        # Add some alfred params.  See https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
        #
        parsed_places ['cache'] = { 'seconds': 300 }

        sorted_items = sorted(parsed_places['items'], key=lambda item: item['title'])
        parsed_places['items'] = sorted_items
        json_string = json.dumps(parsed_places, ensure_ascii=False, sort_keys=True, indent=4)
        print(json_string)

     
    except requests.exceptions.RequestException as e:
        print(f"Error during the request: {e}")
    except ValueError:
        print('Error decoding JSON response (if applicable).')


if __name__ == '__main__':
    main()
        
