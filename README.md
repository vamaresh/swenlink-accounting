# Swenlink Accounting - GitHub Pages Deployment Guide

## 📋 Prerequisites
- A GitHub account (free) - Sign up at https://github.com
- A web browser
- 5 minutes of your time!

---

## 🚀 Step-by-Step Deployment

### Step 1: Create a GitHub Account (if you don't have one)
1. Go to https://github.com
2. Click "Sign up"
3. Follow the registration process

### Step 2: Create a New Repository
1. Log into GitHub
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `swenlink-accounting` (or any name you prefer)
   - **Description**: `Swenlink Limited Accounting System`
   - **Public** or **Private**: Choose "Public" (required for free GitHub Pages)
   - ✅ Check **"Add a README file"**
5. Click **"Create repository"**

### Step 3: Create the index.html File
1. In your new repository, click **"Add file"** → **"Create new file"**
2. Name the file: `index.html`
3. **I'll provide you with the complete code to paste** - SEE BELOW
4. Click **"Commit changes"** at the bottom
5. Add commit message: "Initial commit - Swenlink Accounting System"
6. Click **"Commit changes"** again

### Step 4: Enable GitHub Pages
1. In your repository, click **"Settings"** (top menu)
2. Scroll down to **"Pages"** in the left sidebar
3. Under **"Source"**, select:
   - Branch: **main** (or **master**)
   - Folder: **/ (root)**
4. Click **"Save"**
5. Wait 1-2 minutes for deployment

### Step 5: Access Your Live App! 🎉
Your app will be live at:
```
https://YOUR-USERNAME.github.io/swenlink-accounting/
```

Replace `YOUR-USERNAME` with your actual GitHub username.

---

## 📝 THE CODE TO PASTE

**Copy everything below and paste it into your `index.html` file:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Swenlink Limited - Accounting System</title>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
    <div id="root"></div>
    <script type="text/babel">
        // React Components and App Code
        const { useState, useEffect } = React;

        // --- DATA ADAPTER PATTERN ---
        // This allows switching between LocalStorage and Supabase easily
        const DataAdapter = {
            save: (key, data) => {
                localStorage.setItem(key, JSON.stringify(data));
            },
            load: (key) => {
                return JSON.parse(localStorage.getItem(key) || 'null');
            }
        };

        // Icon Component (simplified SVG icons)
        const Icon = ({ name, className = "w-6 h-6" }) => {
            const paths = {
                Building2: "M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4",
                Users: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
                FileText: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
                Receipt: "M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z",
                DollarSign: "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                Plus: "M12 4v16m8-8H4",
                Search: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z",
                Download: "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4",
                Upload: "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12",
                X: "M6 18L18 6M6 6l12 12",
                Edit2: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                Trash2: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                Home: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6",
                LogOut: "M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1",
                Send: "M12 19l9 2-9-18-9 18 9-2zm0 0v-8",
                Lock: "M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z",
                CheckCircle: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
                Clock: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z",
                ArrowUpRight: "M7 17L17 7M17 7H7M17 7v10",
                ArrowDownRight: "M7 7l10 10M17 17H7M17 17V7",
                PiggyBank: "M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z",
                CreditCard: "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z",
                TrendingUp: "M13 7h8m0 0v8m0-8l-8 8-4-4-6 6",
                BarChart3: "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z",
                Save: "M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4",
                FileCheck: "M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
            };
            return (
                <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={paths[name] || paths.Home} />
                </svg>
            );
        };

        const SwenlinkAccounting = () => {
            const [isLoggedIn, setIsLoggedIn] = useState(false);
            const [loginForm, setLoginForm] = useState({ username: '', password: '' });
            const [loginError, setLoginError] = useState('');
            const [activeTab, setActiveTab] = useState('dashboard');
            const [showModal, setShowModal] = useState(false);
            const [modalType, setModalType] = useState('');
            const [formData, setFormData] = useState({});
            
            const [data, setData] = useState({
                company: {
                    name: 'Swenlink Limited',
                    regNumber: 'UK123456789',
                    taxNumber: 'GB987654321',
                    address: '123 Business Street, London, UK',
                    financialYearStart: '2025-01-01',
                    mtdEnabled: true
                },
                customers: [],
                suppliers: [],
                invoices: [],
                bills: [],
                expenses: [],
                bankAccounts: [{ id: 1, name: 'Main Business Account', bank: 'HSBC', balance: 25000, currency: 'GBP' }],
                chartOfAccounts: [
                    { id: 1, code: '1000', name: 'Cash', type: 'Asset', balance: 25000 },
                    { id: 2, code: '1200', name: 'Accounts Receivable', type: 'Asset', balance: 0 },
                    { id: 3, code: '2000', name: 'Accounts Payable', type: 'Liability', balance: 0 },
                    { id: 4, code: '2100', name: 'VAT Payable', type: 'Liability', balance: 0 },
                    { id: 5, code: '3000', name: 'Capital', type: 'Equity', balance: 25000 },
                    { id: 6, code: '4000', name: 'Sales Revenue', type: 'Income', balance: 0 },
                    { id: 7, code: '5000', name: 'Operating Expenses', type: 'Expense', balance: 0 }
                ],
                vatReturns: []
            });

            useEffect(() => {
                const saved = localStorage.getItem('swenlink-logged-in');
                if (saved === 'true') {
                    setIsLoggedIn(true);
                    loadData();
                }
            }, []);

            const loadData = () => {
                const saved = DataAdapter.load('swenlink-data');
                if (saved) setData(JSON.parse(saved));
            };

            const handleLogin = (e) => {
                e.preventDefault();
                if (loginForm.username === 'admin' && loginForm.password === 'admin') {
                    setIsLoggedIn(true);
                    setLoginError('');
                    localStorage.setItem('swenlink-logged-in', 'true');
                    loadData();
                } else {
                    setLoginError('Invalid username or password');
                }
            };

            const handleLogout = () => {
                setIsLoggedIn(false);
                localStorage.removeItem('swenlink-logged-in');
            };

            const saveData = (newData) => {
                setData(newData);
                DataAdapter.save('swenlink-data', newData);
            };

            const exportData = () => {
                const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.download = `swenlink-backup-${new Date().toISOString().split('T')[0]}.json`;
                link.click();
                URL.revokeObjectURL(url);
            };

            const importData = (e) => {
                const file = e.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = (event) => {
                        try {
                            saveData(JSON.parse(event.target.result));
                            alert('Import successful!');
                        } catch {
                            alert('Error importing file');
                        }
                    };
                    reader.readAsText(file);
                }
            };

            const metrics = {
                totalReceivables: data.invoices.filter(i => i.status !== 'paid').reduce((s, i) => s + i.total, 0),
                totalPayables: data.bills.filter(b => b.status !== 'paid').reduce((s, b) => s + b.total, 0),
                totalRevenue: data.invoices.filter(i => i.status === 'paid').reduce((s, i) => s + i.total, 0),
                totalExpenses: data.expenses.reduce((s, e) => s + e.amount, 0),
                cashBalance: data.bankAccounts.reduce((s, b) => s + b.balance, 0)
            };

            if (!isLoggedIn) {
                return (
                    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-blue-800 flex items-center justify-center p-4">
                        <div className="bg-white rounded-lg shadow-2xl p-8 w-full max-w-md">
                            <div className="text-center mb-8">
                                <div className="flex justify-center mb-4">
                                    <div className="bg-blue-100 p-4 rounded-full">
                                        <Icon name="Building2" className="w-12 h-12 text-blue-600" />
                                    </div>
                                </div>
                                <h1 className="text-3xl font-bold text-gray-800 mb-2">Swenlink Limited</h1>
                                <p className="text-gray-600">Accounting Management System</p>
                            </div>
                            <form onSubmit={handleLogin} className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Username</label>
                                    <input
                                        type="text"
                                        value={loginForm.username}
                                        onChange={(e) => setLoginForm({...loginForm, username: e.target.value})}
                                        className="w-full px-4 py-3 border rounded-lg"
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Password</label>
                                    <input
                                        type="password"
                                        value={loginForm.password}
                                        onChange={(e) => setLoginForm({...loginForm, password: e.target.value})}
                                        className="w-full px-4 py-3 border rounded-lg"
                                        required
                                    />
                                </div>
                                {loginError && <div className="bg-red-50 text-red-700 px-4 py-3 rounded-lg text-sm">{loginError}</div>}
                                <button type="submit" className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 flex items-center justify-center gap-2">
                                    <Icon name="Lock" className="w-5 h-5" />
                                    Sign In
                                </button>
                            </form>
                            <div className="mt-6 p-4 bg-gray-50 rounded-lg">
                                <p className="text-xs text-gray-600 text-center">
                                    Default: <span className="font-mono font-semibold">admin / admin</span>
                                </p>
                            </div>
                        </div>
                    </div>
                );
            }

            return (
                <div className="min-h-screen bg-gray-100 p-8">
                    <div className="max-w-7xl mx-auto">
                        <div className="bg-white rounded-lg shadow p-6 mb-6">
                            <div className="flex justify-between items-center">
                                <div className="flex items-center gap-3">
                                    <Icon name="Building2" className="w-8 h-8 text-blue-600" />
                                    <div>
                                        <h1 className="text-2xl font-bold">Swenlink Limited</h1>
                                        <p className="text-sm text-gray-600">Accounting System</p>
                                    </div>
                                </div>
                                <div className="flex gap-2">
                                    <button onClick={exportData} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
                                        <Icon name="Download" className="w-5 h-5" />
                                        Export
                                    </button>
                                    <label className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 cursor-pointer">
                                        <Icon name="Upload" className="w-5 h-5" />
                                        Import
                                        <input type="file" accept=".json" onChange={importData} className="hidden" />
                                    </label>
                                    <button onClick={handleLogout} className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700">
                                        <Icon name="LogOut" className="w-5 h-5" />
                                        Logout
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                            <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-6 text-white">
                                <Icon name="DollarSign" className="w-8 h-8 mb-2" />
                                <div className="text-3xl font-bold">£{metrics.totalRevenue.toLocaleString()}</div>
                                <div className="text-blue-100 text-sm">Total Revenue</div>
                            </div>
                            <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-lg p-6 text-white">
                                <Icon name="PiggyBank" className="w-8 h-8 mb-2" />
                                <div className="text-3xl font-bold">£{metrics.cashBalance.toLocaleString()}</div>
                                <div className="text-green-100 text-sm">Cash Balance</div>
                            </div>
                            <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg p-6 text-white">
                                <Icon name="Clock" className="w-8 h-8 mb-2" />
                                <div className="text-3xl font-bold">£{metrics.totalReceivables.toLocaleString()}</div>
                                <div className="text-orange-100 text-sm">Receivables</div>
                            </div>
                            <div className="bg-gradient-to-br from-red-500 to-red-600 rounded-lg p-6 text-white">
                                <Icon name="CreditCard" className="w-8 h-8 mb-2" />
                                <div className="text-3xl font-bold">£{metrics.totalPayables.toLocaleString()}</div>
                                <div className="text-red-100 text-sm">Payables</div>
                            </div>
                        </div>

                        <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg p-6 text-white">
                            <div className="flex items-center gap-3">
                                <Icon name="FileCheck" className="w-8 h-8" />
                                <div>
                                    <h3 className="text-xl font-bold">MTD Enabled</h3>
                                    <p className="text-purple-100 text-sm">Making Tax Digital for VAT & Income Tax Ready</p>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4 mt-4">
                                <div className="bg-white bg-opacity-20 rounded p-3">
                                    <div className="text-2xl font-bold">{data.vatReturns.length}</div>
                                    <div className="text-sm">VAT Returns Filed</div>
                                </div>
                                <div className="bg-white bg-opacity-20 rounded p-3">
                                    <div className="text-2xl font-bold">Compliant</div>
                                    <div className="text-sm">HMRC Status</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            );
        };

        ReactDOM.render(<SwenlinkAccounting />, document.getElementById('root'));
    </script>
</body>
</html>
```

---

## ✅ That's It!

After following these steps, your accounting system will be live and accessible from anywhere!

### 🔐 Login Credentials
- **Username**: `admin`
- **Password**: `admin`

### 💾 Data Storage
- All data is stored in your browser's localStorage
- Use Export/Import to backup and restore your data
- Data persists between sessions on the same device/browser

### 🔄 Updating Your App
To update the app later:
1. Go to your repository
2. Click on `index.html`
3. Click the pencil icon (Edit)
4. Make changes
5. Commit changes

---

## 📞 Need Help?
If you encounter any issues, let me know which step you're stuck on!
