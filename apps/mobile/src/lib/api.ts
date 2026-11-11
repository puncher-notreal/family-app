const API_URL = process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:4000';

export function getApiUrl(): string {
  return API_URL;
}

export async function checkApiHealth(): Promise<string> {
  const response = await fetch(`${API_URL}/health`);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  const body = (await response.json()) as { data?: { status?: string; version?: string } };
  return `ok: status=${body.data?.status ?? 'unknown'} version=${body.data?.version ?? 'unknown'}`;
}
