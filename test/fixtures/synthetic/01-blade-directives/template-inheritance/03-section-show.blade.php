{{-- Parent Layout: admin.blade.php --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('page-title', 'Admin Panel')</title>
    <link rel="stylesheet" href="/css/admin.css">
    @yield('custom-styles')
</head>
<body class="admin-layout">
    <div class="admin-container">
        <aside class="admin-sidebar">
            @section('sidebar-menu')
                <div class="sidebar-header">
                    <h2>Admin Panel</h2>
                </div>
                <nav class="sidebar-nav">
                    <ul>
                        <li><a href="/admin/dashboard">Dashboard</a></li>
                        <li><a href="/admin/users">Users</a></li>
                        <li><a href="/admin/content">Content</a></li>
                        <li><a href="/admin/settings">Settings</a></li>
                    </ul>
                </nav>
            @show
        </aside>

        <div class="admin-main">
            <header class="admin-header">
                @section('page-header')
                    <div class="header-left">
                        <h1>@yield('heading', 'Admin Dashboard')</h1>
                    </div>
                    <div class="header-right">
                        <div class="user-menu">
                            <span>{{ auth()->user()->name }}</span>
                            <a href="/logout">Logout</a>
                        </div>
                    </div>
                @show
            </header>

            <div class="admin-content">
                @section('toolbar')
                    <div class="toolbar">
                        <button class="btn btn-primary">New</button>
                        <button class="btn btn-secondary">Export</button>
                        <div class="search-box">
                            <input type="search" placeholder="Search...">
                        </div>
                    </div>
                @show

                <div class="content-area">
                    @yield('main-content')
                </div>

                @section('notifications')
                    <div class="notification-area">
                        <div class="alert alert-info">
                            <strong>Tip:</strong> Use keyboard shortcuts to navigate faster
                        </div>
                    </div>
                @show
            </div>

            <footer class="admin-footer">
                @section('footer-info')
                    <div class="footer-stats">
                        <span>Server Status: <strong class="text-success">Online</strong></span>
                        <span>Last Update: {{ now()->format('H:i:s') }}</span>
                    </div>
                @show
            </footer>
        </div>
    </div>

    <script src="/js/admin.js"></script>
    @yield('page-scripts')
</body>
</html>

{{-- Child Template: user-management.blade.php --}}
@extends('layouts.admin')

@section('page-title', 'User Management - Admin Panel')

@section('heading', 'User Management')

@section('sidebar-menu')
    @parent
    <div class="sidebar-section">
        <h3>User Tools</h3>
        <ul>
            <li><a href="/admin/users/roles">Manage Roles</a></li>
            <li><a href="/admin/users/permissions">Permissions</a></li>
            <li><a href="/admin/users/import">Import Users</a></li>
        </ul>
    </div>
@endsection

@section('page-header')
    @parent
    <div class="header-actions">
        <button class="btn btn-success" onclick="openCreateUserModal()">
            Add New User
        </button>
    </div>
@endsection

@section('toolbar')
    @parent
    <div class="filter-controls">
        <select name="role-filter" id="role-filter">
            <option value="">All Roles</option>
            <option value="admin">Admin</option>
            <option value="editor">Editor</option>
            <option value="viewer">Viewer</option>
        </select>
        <select name="status-filter" id="status-filter">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
        </select>
    </div>
@endsection

@section('main-content')
    <div class="data-table-wrapper">
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Last Login</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($users as $user)
                    <tr>
                        <td>{{ $user->id }}</td>
                        <td>{{ $user->name }}</td>
                        <td>{{ $user->email }}</td>
                        <td><span class="badge badge-{{ $user->role }}">{{ ucfirst($user->role) }}</span></td>
                        <td><span class="status-{{ $user->status }}">{{ ucfirst($user->status) }}</span></td>
                        <td>{{ $user->last_login?->diffForHumans() ?? 'Never' }}</td>
                        <td>
                            <button class="btn-icon" onclick="editUser({{ $user->id }})">Edit</button>
                            <button class="btn-icon" onclick="deleteUser({{ $user->id }})">Delete</button>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>

        <div class="pagination">
            {{ $users->links() }}
        </div>
    </div>
@endsection

@section('notifications')
    @parent
    @if(session('success'))
        <div class="alert alert-success">
            {{ session('success') }}
        </div>
    @endif
    @if(session('error'))
        <div class="alert alert-danger">
            {{ session('error') }}
        </div>
    @endif
@endsection

@section('footer-info')
    @parent
    <div class="footer-actions">
        <span>Total Users: <strong>{{ $totalUsers }}</strong></span>
        <span>Active Users: <strong>{{ $activeUsers }}</strong></span>
    </div>
@endsection

@section('page-scripts')
    <script src="/js/user-management.js"></script>
    <script>
        const userManagement = {
            users: @json($users),
            permissions: @json($permissions)
        };

        function openCreateUserModal() {
            // Modal logic here
        }

        function editUser(userId) {
            // Edit logic here
        }

        function deleteUser(userId) {
            if (confirm('Are you sure you want to delete this user?')) {
                // Delete logic here
            }
        }
    </script>
@endsection
