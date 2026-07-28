<script lang="ts">
	import { resolve } from '$app/paths';

	let { data } = $props();
</script>

<svelte:head>
	<title>References and Search Tools — Equal Sums of Powers</title>
	<meta
		name="description"
		content="Sources, programs, databases, and background material cited by the machine-verified Equal Sums of Powers archive."
	/>
	<link rel="canonical" href="https://powersums.jorisperrenet.com/references/" />
	<meta name="robots" content="index,follow" />
	<meta property="og:title" content="References and Search Tools — Equal Sums of Powers" />
	<meta
		property="og:description"
		content="Sources, programs, databases, and background material cited by the machine-verified Equal Sums of Powers archive."
	/>
	<meta property="og:url" content="https://powersums.jorisperrenet.com/references/" />
	<meta property="og:site_name" content="Equal Sums of Powers" />
</svelte:head>

<div class="min-h-screen bg-[#f5f5f2] text-[#202020]">
	<header class="border-b border-[#b9b9b4] bg-white">
		<div
			class="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6"
		>
			<div class="flex items-center gap-2.5">
				<a
					href="https://jorisperrenet.com/"
					aria-label="Joris Perrenet’s website"
					title="Joris Perrenet’s website"
				>
					<img
						src="/personal-logo.svg"
						alt="Joris Perrenet"
						width="22"
						height="24"
						class="h-6 w-auto"
					/>
				</a>
				<a href={resolve('/')} class="font-serif text-xl font-bold">Equal Sums of Like Powers</a>
			</div>
			<nav class="flex gap-4 text-sm" aria-label="Archive navigation">
				<a href={resolve('/')} class="text-[#0645ad] hover:underline">Archive</a>
				<span class="font-bold" aria-current="page">References</span>
			</nav>
		</div>
	</header>

	<main class="mx-auto max-w-6xl px-4 py-7 sm:px-6 sm:py-9">
		<div class="border-b-2 border-[#555] pb-3">
			<h1 class="font-serif text-3xl font-bold">References and Search Tools</h1>
			<p class="mt-1 max-w-3xl text-sm leading-6 text-[#444]">
				Sources, programs, databases, background material, and public code cited by the verified
				identity and search-coverage tables.
			</p>
		</div>

		{#if data.references.length}
			<ol class="mt-4 border border-[#aaa] bg-white text-sm">
				{#each data.references as reference, index (reference.id)}
					<li
						id={`reference-${reference.id}`}
						class="grid scroll-mt-4 gap-1 border-b border-[#ddd] px-3 py-3 last:border-b-0 sm:grid-cols-[3rem_1fr_auto] sm:gap-3"
					>
						<span class="font-bold">[{index + 1}]</span>
						<a
							href={reference.url}
							target="_blank"
							rel="noreferrer"
							class="break-all text-[#0645ad] hover:underline"
							>{reference.title} — {reference.url} ↗</a
						>
						<span class="text-[#666]">cited {reference.usage_count} times</span>
					</li>
				{/each}
			</ol>
		{:else}
			<p class="mt-4 border border-[#aaa] bg-white px-4 py-5 text-sm">No references recorded.</p>
		{/if}
	</main>

	<footer class="mt-8 border-t border-[#bbb] bg-white">
		<div
			class="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-2 px-4 py-5 text-xs text-[#666] sm:px-6"
		>
			<span>Equal Sums of Like Powers — community-maintained tables of verified identities.</span>
			<a
				href="https://github.com/jorisperrenet/equal_sums_of_powers_website"
				target="_blank"
				rel="noreferrer"
				class="text-[#0645ad] hover:underline focus:underline">Source code on GitHub ↗</a
			>
		</div>
	</footer>
</div>
