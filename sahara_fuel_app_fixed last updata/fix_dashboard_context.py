#!/usr/bin/env python3
"""
Fix dashboard_page.dart - add BuildContext parameter to methods that use AppColors.get()
"""
import re

# Read the file
with open('lib/pages/dashboard_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Methods that were already fixed (have BuildContext context parameter)
FIXED_METHODS = {
    '_buildConsumptionChart',
    '_buildTankStatusSummary',
    '_buildRecentActivities',
    '_buildQuickAlerts',
    '_alertTile'
}

# Find all method definitions and check if they use AppColors.get but don't have context
# Pattern: Widget/void/etc method_name(params) { ... }
method_pattern = r'(Widget|void|bool|String|Color|int)\s+(_\w+)\s*\(([^)]*)\)\s*\{'

def fix_context_in_methods(content):
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this is a method definition
        if re.match(r'\s*(Widget|void|bool|String|Color|int)\s+_\w+\s*\(', line):
            # Extract method signature
            match = re.match(r'(\s*(Widget|void|bool|String|Color|int)\s+(_\w+)\s*\(([^)]*)\))', line)
            if match:
                indent = match.group(1)
                return_type = match.group(2)
                method_name = match.group(3)
                params = match.group(4)
                
                # If method is already fixed, keep it as is
                if method_name not in FIXED_METHODS:
                    # Check the next ~100 lines to see if this method uses AppColors.get
                    method_body = ''
                    j = i + 1
                    brace_count = 1
                    while j < len(lines) and brace_count > 0:
                        method_body += lines[j] + '\n'
                        brace_count += lines[j].count('{') - lines[j].count('}')
                        j += 1
                    
                    # Check if method uses AppColors.get but doesn't have context parameter
                    if 'AppColors.get' in method_body and 'BuildContext context' not in params:
                        # Add context parameter if method has parameters
                        if params.strip():
                            new_params = 'BuildContext context, ' + params
                        else:
                            new_params = 'BuildContext context'
                        
                        # Replace the method signature
                        new_line = indent.replace('(', f'(BuildContext context, ', 1) if '(' in indent else indent
                        if '(' in indent:
                            # Insert context before first parameter or as only parameter
                            if params.strip():
                                new_line = re.sub(r'(\s*\()', r'\1BuildContext context, ', indent)
                            else:
                                new_line = re.sub(r'(\s*\()\s*\)', r'\1BuildContext context\2', indent)
                            fixed_lines.append(new_line + ' {')
                            print(f"Fixed method: {method_name}")
                        else:
                            fixed_lines.append(line)
                    else:
                        fixed_lines.append(line)
                else:
                    fixed_lines.append(line)
            else:
                fixed_lines.append(line)
        else:
            fixed_lines.append(line)
        
        i += 1
    
    return '\n'.join(fixed_lines)

# Apply fix
result = fix_context_in_methods(content)

# Write back
with open('lib/pages/dashboard_page.dart', 'w', encoding='utf-8') as f:
    f.write(result)

print("Dashboard context parameter fixing complete!")
