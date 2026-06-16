import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900">Chợ Truyền Thống</h1>
        <p className="mt-2 text-gray-600">Admin Dashboard</p>
        <Link
          href="/dashboard"
          className="mt-6 inline-block rounded-lg bg-primary px-6 py-3 text-white hover:bg-primary/90"
        >
          Đi đến Dashboard
        </Link>
      </div>
    </div>
  );
}
