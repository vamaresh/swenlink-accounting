#!/usr/bin/env python3
"""
Script to integrate Supabase CRUD operations into index-premium.html
This replaces localStorage operations with Supabase API calls
"""

import re

# Read the helper functions
with open('supabase-helpers.js', 'r') as f:
    helpers = f.read()

# Read the current premium file
with open('index-premium.html', 'r') as f:
    content = f.read()

# Extract the helper functions (without the JS comments at top)
helper_funcs = helpers.split('// CRUD OPERATIONS')[1]

# Find where to insert helpers (after loadCompanyAndData function)
insert_point = content.find('async function loadCompanyAndData()')
if insert_point > 0:
    # Find the end of loadCompanyAndData function
    func_start = insert_point
    brace_count = 0
    in_function = False
    insert_after = insert_point
    
    for i in range(func_start, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_function = True
        elif content[i] == '}':
            brace_count -= 1
            if in_function and brace_count == 0:
                insert_after = i + 1
                break
    
    # Insert helper functions
    content = content[:insert_after] + '\n\n            ' + helper_funcs.strip() + '\n\n            ' + content[insert_after:]

# Now replace the handleSubmit function
old_handle_submit_pattern = r'const handleSubmit = \(e\) => \{[^}]*?saveData\(newData\);[^}]*?closeModal\(\);[^}]*?\};'
new_handle_submit = '''const handleSubmit = async (e) => {
                e.preventDefault();
                const result = await handleSubmitSupabase(e, modalType, editingId, formData, user, supabaseClient);
                if (result.success) {
                    await loadCompanyAndData();
                    closeModal();
                } else {
                    alert('Failed to save. Please try again.');
                }
            };'''

content = re.sub(old_handle_submit_pattern, new_handle_submit, content, flags=re.DOTALL)

# Replace handleDelete function
old_handle_delete_pattern = r'const handleDelete = \(type, id\) => \{.*?saveData\(newData\);.*?\};'
new_handle_delete = '''const handleDelete = async (type, id) => {
                const result = await handleDeleteSupabase(type, id, supabaseClient);
                if (result.success) {
                    await loadCompanyAndData();
                }
            };'''

content = re.sub(old_handle_delete_pattern, new_handle_delete, content, flags=re.DOTALL)

# Write the updated content
with open('index-premium.html', 'w') as f:
    f.write(content)

print("✅ Successfully integrated Supabase operations into index-premium.html")
print("Next steps:")
print("1. Test the application")
print("2. Verify CRUD operations work")
print("3. Check image uploads")
