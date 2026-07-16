<script lang="ts">
	import { resolve } from '$app/paths';
	import { normalizeIdentity } from '$lib/identity';
	import { TARGET_COUNT, TARGET_MAX, TARGET_MIN } from '$lib/target-range';
	import 'katex/dist/katex.min.css';

	let { data, form } = $props();

	const examples = $derived(
		Object.fromEntries(
			data.categories.map((category) => [category.id, storedExample(category)])
		) as Record<string, string>
	);

	function initialCategory() {
		return (form && 'categoryId' in form && form.categoryId) || data.selectedCategory;
	}

	function initialEquation() {
		return (form && 'equationInput' in form && form.equationInput) || '';
	}

	let selectedForForm = $state(initialCategory());
	let equation = $state(initialEquation());
	let selectedCategory = $derived(
		data.categories.find((category) => category.id === data.selectedCategory)
	);
	let exponentGroups = $derived(
		Array.from(new Set(data.categories.map((category) => category.exponent)))
			.sort((left, right) => right - left)
			.map((exponent) => ({
				exponent,
				categories: data.categories.filter((category) => category.exponent === exponent)
			}))
	);
	let selectedExponentGroup = $derived(
		exponentGroups.find((group) => group.exponent === selectedCategory?.exponent)
	);
	let targetCoverage = $derived(
		new Map(data.targetCoverage.map((entry) => [Number(entry.n), Number(entry.solution_count)]))
	);
	const targetValues = Array.from({ length: TARGET_COUNT }, (_, index) => index + TARGET_MIN);

	function chooseCategory(event: Event) {
		selectedForForm = (event.currentTarget as HTMLSelectElement).value;
		equation = '';
	}

	function formatDate(value: string) {
		return new Intl.DateTimeFormat('en-GB', {
			day: '2-digit',
			month: 'short',
			year: 'numeric',
			timeZone: 'UTC'
		}).format(new Date(value));
	}

	function notation(category: (typeof data.categories)[number]) {
		return (
			category.notation ?? `(${category.exponent}, ${category.left_count}, ${category.right_count})`
		);
	}

	function isNegative(value: string | number) {
		return String(value).startsWith('-');
	}

	function absoluteTerm(value: string | number) {
		return isNegative(value) ? String(value).slice(1) : String(value);
	}

	function formatRadius(value: string) {
		return BigInt(value).toString();
	}

	function ordinal(value: number) {
		const remainder = value % 100;
		if (remainder >= 11 && remainder <= 13) return `${value}th`;
		if (value % 10 === 1) return `${value}st`;
		if (value % 10 === 2) return `${value}nd`;
		if (value % 10 === 3) return `${value}rd`;
		return `${value}th`;
	}

	function structuralExample(category: (typeof data.categories)[number]) {
		const left = Array.from({ length: category.left_count }, (_, index) => `a${index + 1}`).join(
			'+'
		);
		if (category.format === 'target') return `N=${left}`;
		const right = Array.from({ length: category.right_count }, (_, index) => `b${index + 1}`).join(
			'+'
		);
		return category.format === 'near_miss' ? `${left}=${right}±1` : `${left}=${right}`;
	}

	function storedExample(category: (typeof data.categories)[number]) {
		if (!category.example_left_terms || !category.example_right_terms) return '';
		const identity = normalizeIdentity(
			category.example_left_terms,
			category.example_right_terms,
			category
		);
		const compactSum = (values: string[]) =>
			values.map((value, index) => `${index && !isNegative(value) ? '+' : ''}${value}`).join('');
		if (category.format === 'target') return `${compactSum(identity.left)}=${identity.right[0]}`;
		if (category.format === 'near_miss') {
			return `${identity.left.join('+')}=${identity.right.join('+')}${Number(identity.residual) < 0 ? '-1' : '+1'}`;
		}
		return `${identity.left.join('+')}=${identity.right.join('+')}`;
	}
</script>

<svelte:head>
	<title>Equal Sums of Like Powers</title>
	<meta name="description" content="A public, verified table of equal sums of like powers." />
</svelte:head>

<div class="min-h-screen bg-[#f5f5f2] text-[#202020]">
	<header class="border-b border-[#b9b9b4] bg-white">
		<div class="mx-auto max-w-6xl px-4 py-5 sm:px-6">
			<div class="flex flex-wrap items-baseline justify-between gap-x-6 gap-y-2">
				<a href={resolve('/')} class="font-serif text-2xl font-bold text-[#202020]"
					>Equal Sums of Like Powers</a
				>
				<div class="flex gap-4 text-sm text-[#555]">
					<a href="#references" class="text-[#0645ad] hover:underline">References</a>
					<a href="#contribute" class="text-[#0645ad] hover:underline">Contribute a result</a>
				</div>
			</div>
		</div>

		<nav class="border-t border-[#ddd] bg-[#ecece8]" aria-label="Power groups">
			<div class="mx-auto flex max-w-6xl overflow-x-auto px-4 sm:px-6">
				<a
					href={resolve('/?view=recent')}
					class={data.showRecent
						? 'border-x border-t-2 border-[#888] border-t-[#333] bg-white px-4 py-2.5 text-sm font-bold whitespace-nowrap text-[#202020]'
						: 'border-r border-[#d0d0cb] px-4 py-2.5 text-sm whitespace-nowrap text-[#0645ad] hover:bg-[#e2e2dd] hover:underline'}
				>
					Recent Results
				</a>
				{#each exponentGroups as group (group.exponent)}
					<a
						href={resolve(`/?category=${group.categories[0].id}`)}
						class={!data.showRecent && group.exponent === selectedCategory?.exponent
							? 'border-x border-t-2 border-[#888] border-t-[#333] bg-white px-4 py-2.5 text-sm font-bold whitespace-nowrap text-[#202020]'
							: 'border-r border-[#d0d0cb] px-4 py-2.5 text-sm whitespace-nowrap text-[#0645ad] hover:bg-[#e2e2dd] hover:underline'}
					>
						{ordinal(group.exponent)} powers
					</a>
				{/each}
			</div>
		</nav>
		{#if !data.showRecent && selectedExponentGroup && selectedExponentGroup.categories.length > 1}
			<nav class="border-t border-[#ddd] bg-white" aria-label="Subproblems">
				<div
					class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-5 gap-y-1 px-4 py-2 text-sm sm:px-6"
				>
					<span class="font-bold">{ordinal(selectedExponentGroup.exponent)}-power category:</span>
					{#each selectedExponentGroup.categories as category (category.id)}
						<a
							href={resolve(`/?category=${category.id}`)}
							aria-current={category.id === data.selectedCategory ? 'page' : undefined}
							class={category.id === data.selectedCategory
								? 'border border-[#555] bg-[#e5e5e0] px-2 py-1 font-bold text-[#202020]'
								: 'border border-[#aaa] bg-white px-2 py-1 text-[#0645ad] hover:bg-[#f2f2ee] hover:underline'}
							>{notation(category)}</a
						>
					{/each}
				</div>
			</nav>
		{/if}
	</header>

	<main class="mx-auto max-w-6xl px-4 py-7 sm:px-6 sm:py-9">
		{#if data.showRecent}
			<section aria-labelledby="recent-heading">
				<div class="border-b-2 border-[#555] pb-3">
					<h1 id="recent-heading" class="font-serif text-3xl font-bold">Recent Results</h1>
				</div>
				<div class="mt-4 overflow-x-auto border border-[#aaa] bg-white">
					<table class="w-full min-w-[980px] border-collapse text-sm">
						<thead>
							<tr class="border-b border-[#888] bg-[#e5e5e0] text-left">
								<th class="w-36 border-r border-[#bbb] px-2 py-1.5 font-bold">Category</th>
								<th class="border-r border-[#bbb] px-2 py-1.5 font-bold">Identity</th>
								<th class="w-40 border-r border-[#bbb] px-2 py-1.5 font-bold">Contributor</th>
								<th class="w-32 border-r border-[#bbb] px-2 py-1.5 font-bold">Date</th>
								<th class="w-64 px-2 py-1.5 font-bold">Tools</th>
							</tr>
						</thead>
						<tbody>
							{#each data.recentResults as result (result.id)}
								{@const identity = normalizeIdentity(result.left_terms, result.right_terms, result)}
								<tr class="border-b border-[#ddd] last:border-b-0 even:bg-[#f7f7f4]">
									<td class="border-r border-[#ddd] px-2 py-2">
										<a
											href={resolve(`/?category=${result.category_id}`)}
											class="text-[#0645ad] hover:underline"
										>
											{result.notation ??
												`(${result.exponent}, ${result.left_count}, ${result.right_count})`}
										</a>
									</td>
									<td
										class="border-r border-[#ddd] px-2 py-2 font-serif text-base whitespace-nowrap"
									>
										{#each identity.left as term, i (i)}
											{#if i}<span class="px-1">{isNegative(term) ? '−' : '+'}</span
												>{:else if isNegative(term)}−{/if}{absoluteTerm(term)}<sup
												>{result.exponent}</sup
											>
										{/each}
										<span class="px-2 font-sans font-bold">=</span>
										{#if result.format === 'near_miss'}
											{#each identity.right as term, i (i)}
												{#if i}<span class="px-1">+</span>{/if}{term}<sup>{result.exponent}</sup>
											{/each}
											<span class="px-1">{Number(identity.residual) < 0 ? '−' : '+'}</span>1
										{:else}
											{#each identity.right as term, i (i)}
												{#if i}<span class="px-1">+</span
													>{/if}{term}{#if result.format !== 'target'}<sup>{result.exponent}</sup
													>{/if}
											{/each}
										{/if}
									</td>
									<td class="border-r border-[#ddd] px-2 py-2">{result.username}</td>
									<td class="border-r border-[#ddd] px-2 py-2 whitespace-nowrap"
										>{formatDate(result.created_at)}</td
									>
									<td class="px-2 py-2">
										{#if result.tool_reference_id}
											[{result.tool_reference_id}] {result.tool_name}
										{:else if result.tool_name}{result.tool_name}{/if}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</section>

			<section class="mt-10 border border-[#aaa] bg-white p-5" aria-labelledby="notation-heading">
				<h2 id="notation-heading" class="font-serif text-2xl font-bold">Notation</h2>
				<p class="mt-3 text-sm leading-6 text-[#333]">
					The archive uses compact labels for different equal-sum and near-miss problems. Every
					published identity is checked with exact integer arithmetic and must be primitive: the
					bases have no common factor greater than 1.
				</p>
				<div class="mt-5 grid gap-5 md:grid-cols-3">
					<div>
						<h3 class="font-bold">Equal sums</h3>
						<div class="mt-2 overflow-x-auto">{@html data.notationFormulas.equalLabel}</div>
						<div class="mt-2 overflow-x-auto">{@html data.notationFormulas.equalEquation}</div>
						<p class="mt-2 text-xs text-[#555]">Search bounds:</p>
						<div class="overflow-x-auto">{@html data.notationFormulas.unsignedSearchBounds}</div>
					</div>
					<div>
						<h3 class="font-bold">Near misses</h3>
						<div class="mt-2 overflow-x-auto">{@html data.notationFormulas.nearMissLabel}</div>
						<div class="mt-2 overflow-x-auto">{@html data.notationFormulas.nearMissEquation}</div>
						<p class="mt-2 text-xs text-[#555]">Search bounds:</p>
						<div class="overflow-x-auto">{@html data.notationFormulas.unsignedSearchBounds}</div>
					</div>
					<div>
						<h3 class="font-bold">Integer targets</h3>
						<div class="mt-2">{@html data.notationFormulas.targetLabel}</div>
						<div class="mt-2">{@html data.notationFormulas.targetEquation}</div>
						<div>{@html data.notationFormulas.targetRange}</div>
						<p class="mt-2 text-xs text-[#555]">Search bounds:</p>
						<div>{@html data.notationFormulas.signedSearchBounds}</div>
					</div>
				</div>
				<p class="mt-4 text-sm text-[#555]">
					Categories with smaller <i>a</i> + <i>b</i> are listed first because they are generally more
					difficult. The site opens on the `(7, 4, 4)` pairs problem.
				</p>
			</section>
		{:else}
			<section aria-labelledby="leaderboard-heading">
				<div class="border-b-2 border-[#555] pb-3">
					<div class="flex flex-wrap items-end justify-between gap-3">
						<h1 id="leaderboard-heading" class="font-serif text-3xl font-bold">Leaderboard</h1>
						<div class="flex items-center gap-3 text-sm">
							<span class="text-[#555]">{data.selectedCount} recorded identities</span>
							<a
								href={resolve(`/export.csv?category=${data.selectedCategory}&sort=${data.sort}`)}
								class="border border-[#888] bg-white px-2 py-1 text-[#0645ad] hover:bg-[#f0f0ec] hover:underline"
								>Export CSV</a
							>
						</div>
					</div>
				</div>
				{#if selectedCategory?.format === 'target'}
					<nav class="mt-3 text-sm" aria-label="Result sorting">
						<span class="font-bold">Sort by:</span>
						<a
							href={resolve(`/?category=${data.selectedCategory}`)}
							class={data.sort === 'n'
								? 'ml-2 font-bold text-[#202020]'
								: 'ml-2 text-[#0645ad] hover:underline'}>N</a
						>
						<span class="px-1 text-[#888]">|</span>
						<a
							href={resolve(`/?category=${data.selectedCategory}&sort=date`)}
							class={data.sort === 'date'
								? 'font-bold text-[#202020]'
								: 'text-[#0645ad] hover:underline'}>Date</a
						>
					</nav>
				{/if}

				{#if selectedCategory?.format === 'target'}
					<div class="mt-4 border border-[#aaa] bg-white p-4">
						<p class="text-sm">
							The integer target is restricted to <strong>{TARGET_MIN} ≤ N ≤ {TARGET_MAX}</strong>.
							{data.targetCoverage.length} of {TARGET_COUNT} target values currently have at least one
							result.
						</p>
						<details class="mt-3">
							<summary class="cursor-pointer text-sm font-bold text-[#0645ad] hover:underline"
								>Show the N coverage table</summary
							>
							<p class="mt-2 text-xs text-[#666]">
								Dark cells have at least one recorded solution.
							</p>
							<div
								class="mt-2 grid max-h-[32rem] grid-cols-[repeat(10,minmax(0,1fr))] overflow-y-auto border border-[#bbb] text-center text-[10px] sm:grid-cols-[repeat(20,minmax(0,1fr))]"
							>
								{#each targetValues as n (n)}
									<div
										title={targetCoverage.has(n)
											? `N=${n}: ${targetCoverage.get(n)} solution(s)`
											: `N=${n}: not found`}
										class={targetCoverage.has(n)
											? 'border-r border-b border-[#bbb] bg-[#555] px-0.5 py-1 text-white'
											: 'border-r border-b border-[#ddd] bg-white px-0.5 py-1 text-[#777]'}
									>
										{n}
									</div>
								{/each}
							</div>
						</details>
					</div>
				{/if}

				{#if data.submissions.length}
					<div class="mt-4 overflow-x-auto border border-[#aaa] bg-white">
						<table class="w-full min-w-[850px] border-collapse text-sm">
							<thead>
								<tr class="border-b border-[#888] bg-[#e5e5e0] text-left">
									<th class="border-r border-[#bbb] px-2 py-1.5 font-bold">Identity</th>
									<th class="w-40 border-r border-[#bbb] px-2 py-1.5 font-bold">Contributor</th>
									<th class="w-32 border-r border-[#bbb] px-2 py-1.5 font-bold">Date</th>
									<th class="w-64 px-2 py-1.5 font-bold">Tools</th>
								</tr>
							</thead>
							<tbody>
								{#each data.submissions as submission (submission.id)}
									{@const identity = normalizeIdentity(
										submission.left_terms,
										submission.right_terms,
										selectedCategory!
									)}
									<tr
										class="border-b border-[#ddd] last:border-b-0 even:bg-[#f7f7f4] hover:bg-[#fffbdc]"
									>
										<td
											class="border-r border-[#ddd] px-2 py-2 font-serif text-base whitespace-nowrap"
										>
											{#each identity.left as term, i (i)}
												{#if i}
													<span class="px-1">{isNegative(term) ? '−' : '+'}</span>
												{:else if isNegative(term)}−{/if}{absoluteTerm(term)}<sup
													>{selectedCategory?.exponent}</sup
												>
											{/each}
											<span class="px-2 font-sans font-bold">=</span>
											{#if selectedCategory?.format === 'near_miss'}
												{#each identity.right as term, i (i)}
													{#if i}<span class="px-1">+</span>{/if}{term}<sup
														>{selectedCategory.exponent}</sup
													>
												{/each}
												<span class="px-1">{Number(identity.residual) < 0 ? '−' : '+'}</span>1
											{:else}
												{#each identity.right as term, i (i)}
													{#if i}<span class="px-1">+</span
														>{/if}{term}{#if selectedCategory?.format !== 'target'}<sup
															>{selectedCategory?.exponent}</sup
														>{/if}
												{/each}
											{/if}
										</td>
										<td class="border-r border-[#ddd] px-2 py-2">{submission.username}</td>
										<td class="border-r border-[#ddd] px-2 py-2 whitespace-nowrap"
											>{formatDate(submission.created_at)}</td
										>
										<td class="px-2 py-2 text-sm">
											{#if submission.tool_reference_id}
												<a
													href={`#reference-${submission.tool_reference_id}`}
													class="text-[#0645ad] hover:underline"
													>[{submission.tool_reference_id}] {submission.tool_name}</a
												>
											{:else if submission.tool_url}
												<a
													href={submission.tool_url}
													target="_blank"
													rel="noreferrer"
													class="text-[#0645ad] hover:underline"
													>{submission.tool_name || 'Tool / code'} ↗</a
												>
											{:else if submission.tool_name}
												{submission.tool_name}
											{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
					<p class="mt-2 text-xs text-[#666]">
						Sorted by {data.sort === 'n' ? 'N' : 'discovery date, newest first'}. Scroll
						horizontally on narrow screens.
					</p>
					{#if data.selectedCount > data.pageSize}
						<nav
							class="mt-4 flex items-center justify-center gap-4 text-sm"
							aria-label="Result pages"
						>
							{#if data.page > 1}
								<a
									href={resolve(
										`/?category=${data.selectedCategory}&sort=${data.sort}&page=${data.page - 1}`
									)}
									class="text-[#0645ad] hover:underline">← Previous</a
								>
							{/if}
							<span>Page {data.page} of {Math.ceil(data.selectedCount / data.pageSize)}</span>
							{#if data.page * data.pageSize < data.selectedCount}
								<a
									href={resolve(
										`/?category=${data.selectedCategory}&sort=${data.sort}&page=${data.page + 1}`
									)}
									class="text-[#0645ad] hover:underline">Next →</a
								>
							{/if}
						</nav>
					{/if}
				{:else}
					<div class="mt-4 border border-[#aaa] bg-white px-5 py-10 text-center">
						<p>No non-trivial identities have been recorded in this category.</p>
						<a href="#contribute" class="mt-2 inline-block text-sm text-[#0645ad] hover:underline"
							>Contribute the first one</a
						>
					</div>
				{/if}
			</section>

			<section
				class="mt-10 border-t-2 border-[#555] pt-6"
				aria-labelledby="search-coverage-heading"
			>
				<div class="flex flex-wrap items-end justify-between gap-3">
					<h2 id="search-coverage-heading" class="font-serif text-2xl font-bold">
						Search coverage
					</h2>
					<p class="text-sm text-[#555]">{data.searchClaims.length} search claims</p>
				</div>
				<p class="mt-1 text-sm leading-6 text-[#444]">
					Contributor-reported searches that found no additional identities up to the stated radius.
					These claims are not independently verified.
				</p>

				{#if data.searchClaims.length}
					<div class="mt-4 overflow-x-auto border border-[#aaa] bg-white">
						<table class="w-full min-w-[950px] border-collapse text-sm">
							<thead>
								<tr class="border-b border-[#888] bg-[#e5e5e0] text-left">
									<th class="w-32 border-r border-[#bbb] px-3 py-2 font-bold">Lower radius</th>
									<th class="w-32 border-r border-[#bbb] px-3 py-2 font-bold">Upper radius</th>
									<th class="w-28 border-r border-[#bbb] px-3 py-2 font-bold">Type</th>
									<th class="w-40 border-r border-[#bbb] px-3 py-2 font-bold">Researcher</th>
									<th class="w-64 border-r border-[#bbb] px-3 py-2 font-bold">Tools used</th>
									<th class="border-r border-[#bbb] px-3 py-2 font-bold">Notes</th>
									<th class="w-32 px-3 py-2 font-bold">Date</th>
								</tr>
							</thead>
							<tbody>
								{#each data.searchClaims as claim (claim.id)}
									<tr
										class="border-b border-[#ddd] last:border-b-0 even:bg-[#f7f7f4] hover:bg-[#fffbdc]"
									>
										<td class="border-r border-[#ddd] px-3 py-3 font-serif text-base">
											{formatRadius(claim.lower_radius)} ≤ {selectedCategory?.format === 'target'
												? '|xᵢ|'
												: 'xᵢ'}
										</td>
										<td class="border-r border-[#ddd] px-3 py-3 font-serif text-base">
											{selectedCategory?.format === 'target' ? '|xᵢ|' : 'xᵢ'} &lt; {formatRadius(
												claim.upper_radius
											)}
										</td>
										<td class="border-r border-[#ddd] px-3 py-3 capitalize">{claim.search_type}</td>
										<td class="border-r border-[#ddd] px-3 py-3">{claim.username}</td>
										<td class="border-r border-[#ddd] px-3 py-3">
											{#if claim.tool_reference_id}
												<a
													href={`#reference-${claim.tool_reference_id}`}
													class="text-[#0645ad] hover:underline"
													>[{claim.tool_reference_id}] {claim.tool_name}</a
												>
											{:else if claim.tool_url}
												<a
													href={claim.tool_url}
													target="_blank"
													rel="noreferrer"
													class="text-[#0645ad] hover:underline">{claim.tool_name} ↗</a
												>
											{:else}
												{claim.tool_name}
											{/if}
										</td>
										<td class="border-r border-[#ddd] px-3 py-3 leading-5"
											>{claim.comment || '—'}</td
										>
										<td class="px-3 py-3 whitespace-nowrap">{formatDate(claim.created_at)}</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{:else}
					<p class="mt-4 border border-[#aaa] bg-white px-4 py-6 text-center text-sm">
						No search coverage has been reported for this category.
					</p>
				{/if}

				<details class="mt-4 border border-[#aaa] bg-white">
					<summary class="cursor-pointer bg-[#e5e5e0] px-4 py-2.5 text-sm font-bold"
						>Report a search with no new results</summary
					>
					<form method="POST" action="?/claimSearch" class="border-t border-[#aaa] p-4 sm:p-5">
						<p class="mb-4 text-sm leading-6 text-[#444]">
							Please link to source code or a public tool where possible. Open methods make coverage
							claims easier to reproduce and extend.
						</p>
						<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
							<label class="block text-sm font-bold"
								>Category
								<select
									name="category"
									class="mt-1 block w-full border border-[#888] bg-white px-2 py-2 font-normal"
								>
									{#each exponentGroups as group (group.exponent)}
										<optgroup label={`${ordinal(group.exponent)} powers`}>
											{#each group.categories as category (category.id)}
												<option
													value={category.id}
													selected={category.id ===
														((form?.kind === 'claim' && 'categoryId' in form && form.categoryId) ||
															data.selectedCategory)}>{notation(category)}</option
												>
											{/each}
										</optgroup>
									{/each}
								</select>
							</label>
							<label class="block text-sm font-bold"
								>Username
								<input
									name="username"
									value={form?.kind === 'claim' && 'username' in form ? form.username : ''}
									maxlength="32"
									required
									class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
								/>
							</label>
							<label class="block text-sm font-bold"
								>Lower radius
								<input
									name="lowerRadius"
									value={form?.kind === 'claim' && 'lowerRadius' in form ? form.lowerRadius : '0'}
									inputmode="numeric"
									placeholder="e.g. 0"
									maxlength="50"
									required
									class="mt-1 block w-full border border-[#888] px-2 py-2 font-mono font-normal"
								/>
							</label>
							<label class="block text-sm font-bold"
								>Upper radius
								<input
									name="upperRadius"
									value={form?.kind === 'claim' && 'upperRadius' in form ? form.upperRadius : ''}
									inputmode="numeric"
									placeholder="e.g. 30000"
									maxlength="50"
									required
									class="mt-1 block w-full border border-[#888] px-2 py-2 font-mono font-normal"
								/>
							</label>
							<label class="block text-sm font-bold"
								>Search type
								<select
									name="searchType"
									class="mt-1 block w-full border border-[#888] bg-white px-2 py-2 font-normal"
								>
									<option value="exhaustive">Exhaustive</option>
									<option value="partial">Targeted / partial</option>
								</select>
							</label>
						</div>
						<div class="mt-4 grid gap-4 sm:grid-cols-2">
							<label class="block text-sm font-bold"
								>Tool or program name
								<input
									name="toolName"
									value={form?.kind === 'claim' && 'toolName' in form ? form.toolName : ''}
									maxlength="80"
									required
									class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
								/>
							</label>
							<label class="block text-sm font-bold"
								>Tool or source-code link <span class="font-normal text-[#666]">(recommended)</span>
								<input
									name="toolUrl"
									list="known-references"
									value={form?.kind === 'claim' && 'toolUrl' in form ? form.toolUrl : ''}
									type="url"
									maxlength="300"
									placeholder="https://github.com/…"
									class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
								/>
							</label>
						</div>
						<label class="mt-4 block text-sm font-bold"
							>Method and notes <span class="font-normal text-[#666]"
								>(optional, 500 characters)</span
							>
							<textarea
								name="comment"
								maxlength="500"
								rows="3"
								class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
								>{form?.kind === 'claim' && 'comment' in form ? form.comment : ''}</textarea
							>
						</label>
						<label class="absolute -left-[9999px]" aria-hidden="true"
							>Website<input name="claimWebsite" tabindex="-1" autocomplete="off" /></label
						>
						{#if form?.kind === 'claim' && form.message}
							<p
								class={form.success
									? 'mt-4 border border-[#7ba17b] bg-[#eef8ee] px-3 py-2 text-sm text-[#235a23]'
									: 'mt-4 border border-[#c78f8f] bg-[#fff0f0] px-3 py-2 text-sm text-[#8a2020]'}
								role="status"
							>
								{form.message}
							</p>
						{/if}
						<button
							type="submit"
							class="mt-4 border border-[#333] bg-[#e7e7e2] px-4 py-2 text-sm font-bold shadow-[inset_0_1px_white] hover:bg-[#d8d8d2]"
							>Publish search claim</button
						>
					</form>
				</details>
			</section>

			<details id="contribute" class="mt-6 border border-[#aaa] bg-white">
				<summary class="cursor-pointer bg-[#e5e5e0] px-4 py-2.5 text-sm font-bold">
					Contribute a result
				</summary>
				<form method="POST" action="?/submitIdentity" class="border-t border-[#aaa] p-4 sm:p-5">
					<p class="mb-4 text-sm leading-6 text-[#444]">
						Choose a category and enter one equation per line, up to 50 at a time. Powers may be
						omitted. The complete list is published only when every identity is exact and new.
					</p>
					<div class="grid gap-4 md:grid-cols-[220px_180px_1fr]">
						<label class="block text-sm font-bold">
							Category
							<select
								name="category"
								value={selectedForForm}
								onchange={chooseCategory}
								class="mt-1 block w-full border border-[#888] bg-white px-2 py-2 font-normal"
							>
								{#each exponentGroups as group (group.exponent)}
									<optgroup label={`${ordinal(group.exponent)} powers`}>
										{#each group.categories as category (category.id)}
											<option value={category.id}>{notation(category)}</option>
										{/each}
									</optgroup>
								{/each}
							</select>
						</label>

						<label class="block text-sm font-bold">
							Username
							<input
								name="username"
								value={form?.kind === 'identity' && 'username' in form ? form.username : ''}
								maxlength="32"
								required
								class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
							/>
						</label>

						<label class="block text-sm font-bold">
							Equations <span class="font-normal text-[#666]">(one per line)</span>
							<textarea
								name="equation"
								bind:value={equation}
								required
								maxlength="25049"
								rows="5"
								spellcheck="false"
								class="mt-1 block w-full border border-[#888] px-2 py-2 font-mono font-normal"
							></textarea>
							<span class="mt-1 block font-normal text-[#666]">
								{#if examples[selectedForForm]}
									Example: <code>{examples[selectedForForm]}</code>
								{:else}
									Format: <code
										>{structuralExample(
											data.categories.find((category) => category.id === selectedForForm)!
										)}</code
									>
								{/if}
							</span>
						</label>
					</div>

					<div class="mt-4 grid gap-4 sm:grid-cols-2">
						<label class="block text-sm font-bold"
							>Tool or program name <span class="font-normal text-[#666]">(optional)</span>
							<input
								name="resultToolName"
								maxlength="80"
								class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
							/>
						</label>
						<label class="block text-sm font-bold"
							>Tool or source-code link <span class="font-normal text-[#666]">(recommended)</span>
							<input
								name="resultToolUrl"
								list="known-references"
								type="url"
								maxlength="300"
								placeholder="https://github.com/…"
								class="mt-1 block w-full border border-[#888] px-2 py-2 font-normal"
							/>
						</label>
					</div>

					<label class="absolute -left-[9999px]" aria-hidden="true"
						>Website<input name="website" tabindex="-1" autocomplete="off" /></label
					>

					{#if form?.kind === 'identity' && form.message}
						<p
							class={form.success
								? 'mt-4 border border-[#7ba17b] bg-[#eef8ee] px-3 py-2 text-sm text-[#235a23]'
								: 'mt-4 border border-[#c78f8f] bg-[#fff0f0] px-3 py-2 text-sm text-[#8a2020]'}
							role="status"
						>
							{form.message}
						</p>
					{/if}

					<div class="mt-4 flex flex-wrap items-center gap-4">
						<button
							type="submit"
							class="border border-[#333] bg-[#e7e7e2] px-4 py-2 text-sm font-bold shadow-[inset_0_1px_white] hover:bg-[#d8d8d2]"
							>Verify and publish</button
						>
						<span class="text-xs text-[#666]"
							>Exact integer check · duplicate detection · public record</span
						>
					</div>
				</form>
			</details>

			<section
				id="references"
				class="mt-12 border-t-2 border-[#555] pt-6"
				aria-labelledby="references-heading"
			>
				<h2 id="references-heading" class="font-serif text-2xl font-bold">References</h2>
				<p class="mt-1 text-sm leading-6 text-[#444]">
					Shared tools, source code, background pages, and source lists cited by the tables.
				</p>
				{#if data.references.length}
					<ol class="mt-4 border border-[#aaa] bg-white text-sm">
						{#each data.references as reference (reference.id)}
							<li
								id={`reference-${reference.id}`}
								class="grid gap-1 border-b border-[#ddd] px-3 py-2 last:border-b-0 sm:grid-cols-[3rem_1fr_auto] sm:gap-3"
							>
								<span class="font-bold">[{reference.id}]</span>
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
					<p class="mt-4 border border-[#aaa] bg-white px-4 py-5 text-sm">
						No references recorded.
					</p>
				{/if}
			</section>

			<datalist id="known-references">
				{#each data.references as reference (reference.id)}
					<option value={reference.url}>{reference.title}</option>
				{/each}
			</datalist>
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
