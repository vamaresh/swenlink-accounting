// Supabase Helper Functions for Premium Version
// Integrated directly into index.html (premium build)

// ====================
// CRUD OPERATIONS
// ====================

async function handleSubmitSupabase(e, modalType, editingId, formData, user, supabaseClient) {
    e.preventDefault();
    
    try {
        switch(modalType) {
            case 'customer':
                if (editingId) {
                    await supabaseClient
                        .from('customers')
                        .update({
                            name: formData.name,
                            email: formData.email,
                            phone: formData.phone,
                            address: formData.address
                        })
                        .eq('id', editingId);
                } else {
                    await supabaseClient
                        .from('customers')
                        .insert({
                            clerk_user_id: user.id,
                            name: formData.name,
                            email: formData.email,
                            phone: formData.phone,
                            address: formData.address
                        });
                }
                break;

            case 'supplier':
                if (editingId) {
                    await supabaseClient
                        .from('suppliers')
                        .update({
                            name: formData.name,
                            email: formData.email,
                            phone: formData.phone,
                            address: formData.address
                        })
                        .eq('id', editingId);
                } else {
                    await supabaseClient
                        .from('suppliers')
                        .insert({
                            clerk_user_id: user.id,
                            name: formData.name,
                            email: formData.email,
                            phone: formData.phone,
                            address: formData.address
                        });
                }
                break;

            case 'invoice':
                const invoiceSubtotal = parseFloat(formData.subtotal || 0);
                const invoiceVATRate = parseFloat(formData.vatRate || 0.20);
                const invoiceVAT = parseFloat(formData.vat || (invoiceSubtotal * invoiceVATRate));
                
                if (editingId) {
                    await supabaseClient
                        .from('invoices')
                        .update({
                            customer_id: formData.customerId,
                            invoice_number: formData.invoiceNumber,
                            date: formData.date,
                            due_date: formData.dueDate,
                            description: formData.description,
                            subtotal: invoiceSubtotal,
                            vat_rate: invoiceVATRate,
                            vat: invoiceVAT,
                            total: invoiceSubtotal + invoiceVAT,
                            status: formData.status || 'unpaid'
                        })
                        .eq('id', editingId);
                } else {
                    await supabaseClient
                        .from('invoices')
                        .insert({
                            clerk_user_id: user.id,
                            customer_id: formData.customerId,
                            invoice_number: formData.invoiceNumber,
                            date: formData.date || new Date().toISOString().split('T')[0],
                            due_date: formData.dueDate,
                            description: formData.description,
                            subtotal: invoiceSubtotal,
                            vat_rate: invoiceVATRate,
                            vat: invoiceVAT,
                            total: invoiceSubtotal + invoiceVAT,
                            status: formData.status || 'unpaid'
                        });
                }
                break;

            case 'bill':
                const billSubtotal = parseFloat(formData.subtotal || 0);
                const billVATRate = parseFloat(formData.vatRate || 0.20);
                const billVAT = parseFloat(formData.vat || (billSubtotal * billVATRate));
                
                if (editingId) {
                    await supabaseClient
                        .from('bills')
                        .update({
                            supplier_id: formData.supplierId,
                            bill_number: formData.billNumber,
                            date: formData.date,
                            due_date: formData.dueDate,
                            description: formData.description,
                            subtotal: billSubtotal,
                            vat_rate: billVATRate,
                            vat: billVAT,
                            total: billSubtotal + billVAT,
                            status: formData.status || 'unpaid'
                        })
                        .eq('id', editingId);
                    
                    // Handle bill images
                    if (formData.images && formData.images.length > 0) {
                        // Delete old images
                        await supabaseClient
                            .from('bill_images')
                            .delete()
                            .eq('bill_id', editingId);
                        
                        // Insert new images
                        const imageRecords = formData.images.map(url => ({
                            bill_id: editingId,
                            image_url: url
                        }));
                        await supabaseClient.from('bill_images').insert(imageRecords);
                    }
                } else {
                    const { data: newBill, error } = await supabaseClient
                        .from('bills')
                        .insert({
                            clerk_user_id: user.id,
                            supplier_id: formData.supplierId,
                            bill_number: formData.billNumber,
                            date: formData.date || new Date().toISOString().split('T')[0],
                            due_date: formData.dueDate,
                            description: formData.description,
                            subtotal: billSubtotal,
                            vat_rate: billVATRate,
                            vat: billVAT,
                            total: billSubtotal + billVAT,
                            status: formData.status || 'unpaid'
                        })
                        .select()
                        .single();
                    
                    if (!error && formData.images && formData.images.length > 0) {
                        const imageRecords = formData.images.map(url => ({
                            bill_id: newBill.id,
                            image_url: url
                        }));
                        await supabaseClient.from('bill_images').insert(imageRecords);
                    }
                }
                break;

            case 'expense':
                if (editingId) {
                    await supabaseClient
                        .from('expenses')
                        .update({
                            date: formData.date,
                            category: formData.category,
                            description: formData.description,
                            amount: parseFloat(formData.amount || 0),
                            payment_method: formData.paymentMethod
                        })
                        .eq('id', editingId);
                    
                    // Handle expense images
                    if (formData.images && formData.images.length > 0) {
                        await supabaseClient
                            .from('expense_images')
                            .delete()
                            .eq('expense_id', editingId);
                        
                        const imageRecords = formData.images.map(url => ({
                            expense_id: editingId,
                            image_url: url
                        }));
                        await supabaseClient.from('expense_images').insert(imageRecords);
                    }
                } else {
                    const { data: newExpense, error } = await supabaseClient
                        .from('expenses')
                        .insert({
                            clerk_user_id: user.id,
                            date: formData.date || new Date().toISOString().split('T')[0],
                            category: formData.category,
                            description: formData.description,
                            amount: parseFloat(formData.amount || 0),
                            payment_method: formData.paymentMethod
                        })
                        .select()
                        .single();
                    
                    if (!error && formData.images && formData.images.length > 0) {
                        const imageRecords = formData.images.map(url => ({
                            expense_id: newExpense.id,
                            image_url: url
                        }));
                        await supabaseClient.from('expense_images').insert(imageRecords);
                    }
                }
                break;

            case 'account':
                if (editingId) {
                    await supabaseClient
                        .from('chart_of_accounts')
                        .update({
                            code: formData.code,
                            name: formData.name,
                            type: formData.type,
                            balance: parseFloat(formData.balance || 0)
                        })
                        .eq('id', editingId);
                } else {
                    await supabaseClient
                        .from('chart_of_accounts')
                        .insert({
                            clerk_user_id: user.id,
                            code: formData.code,
                            name: formData.name,
                            type: formData.type,
                            balance: parseFloat(formData.balance || 0)
                        });
                }
                break;

            case 'bankAccount':
                if (editingId) {
                    await supabaseClient
                        .from('bank_accounts')
                        .update({
                            name: formData.name,
                            bank: formData.bank,
                            account_number: formData.accountNumber,
                            sort_code: formData.sortCode,
                            balance: parseFloat(formData.balance || 0),
                            currency: formData.currency || 'GBP'
                        })
                        .eq('id', editingId);
                } else {
                    await supabaseClient
                        .from('bank_accounts')
                        .insert({
                            clerk_user_id: user.id,
                            name: formData.name,
                            bank: formData.bank,
                            account_number: formData.accountNumber,
                            sort_code: formData.sortCode,
                            balance: parseFloat(formData.balance || 0),
                            currency: formData.currency || 'GBP'
                        });
                }
                break;
        }
        
        return { success: true };
    } catch (error) {
        console.error('Error submitting data:', error);
        return { success: false, error };
    }
}

async function handleDeleteSupabase(type, id, supabaseClient) {
    if (!confirm('Are you sure you want to delete this item?')) return { success: false };
    
    try {
        const tableMap = {
            'customer': 'customers',
            'supplier': 'suppliers',
            'invoice': 'invoices',
            'bill': 'bills',
            'expense': 'expenses',
            'account': 'chart_of_accounts',
            'vat': 'vat_returns',
            'bankAccount': 'bank_accounts'
        };
        
        const tableName = tableMap[type];
        if (!tableName) return { success: false };
        
        const { error } = await supabaseClient
            .from(tableName)
            .delete()
            .eq('id', id);
        
        if (error) throw error;
        return { success: true };
    } catch (error) {
        console.error('Error deleting:', error);
        return { success: false, error };
    }
}

async function generateVATReturnSupabase(startDate, endDate, user, supabaseClient, invoices, bills) {
    try {
        const periodInvoices = invoices.filter(i => 
            i.date >= startDate && i.date <= endDate
        );
        const periodBills = bills.filter(b => 
            b.date >= startDate && b.date <= endDate
        );
        
        const outputVAT = periodInvoices.reduce((sum, i) => sum + parseFloat(i.vat || 0), 0);
        const inputVAT = periodBills.reduce((sum, b) => sum + parseFloat(b.vat || 0), 0);
        const vatDue = outputVAT - inputVAT;
        
        const { data, error } = await supabaseClient
            .from('vat_returns')
            .insert({
                clerk_user_id: user.id,
                period_start: startDate,
                period_end: endDate,
                output_vat: outputVAT,
                input_vat: inputVAT,
                vat_due: vatDue,
                status: 'draft',
                generated_date: new Date().toISOString().split('T')[0]
            })
            .select()
            .single();
        
        if (error) throw error;
        
        alert(`VAT Return Generated!\nOutput VAT: £${outputVAT.toFixed(2)}\nInput VAT: £${inputVAT.toFixed(2)}\nVAT Due: £${vatDue.toFixed(2)}\n\nStatus: Draft - Review and file when ready`);
        return { success: true, data };
    } catch (error) {
        console.error('Error generating VAT return:', error);
        return { success: false, error };
    }
}

async function fileVATReturnSupabase(id, supabaseClient) {
    try {
        const { error } = await supabaseClient
            .from('vat_returns')
            .update({
                status: 'filed',
                filed_date: new Date().toISOString().split('T')[0]
            })
            .eq('id', id);
        
        if (error) throw error;
        
        alert('VAT Return marked as filed successfully!');
        return { success: true };
    } catch (error) {
        console.error('Error filing VAT return:', error);
        alert('Failed to file VAT return');
        return { success: false, error };
    }
}
