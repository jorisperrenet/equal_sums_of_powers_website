<script lang="ts">
	import './layout.css';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href="/favicon.png" type="image/png" />
	<meta name="theme-color" content="#f7f7f3" />
</svelte:head>
{@render children()}
