import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useMemo, useState, useEffect } from 'react';
import { Box } from '@chakra-ui/react';
import Loader from '@/components/Loader';
import Pagination from '@/components/Pagination';
import { useStore } from '@/stores';
import useSyncRuns from '@/hooks/syncs/useSyncRuns';
import { SyncRunsColumns } from './SyncRunsColumns';
import DataTable from '@/components/DataTable';
import { Row } from '@tanstack/react-table';
import { SyncRunsResponse } from '../types';
import RowsNotFound from '@/components/DataTable/RowsNotFound';

const SyncRuns = () => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { syncId } = useParams();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  const pageId = searchParams.get('page');
  const [currentPage, setCurrentPage] = useState(Number(pageId) || 1);

  useEffect(() => {
    setSearchParams({ page: currentPage.toString() });
  }, [currentPage, setSearchParams]);

  const { data, isLoading } = useSyncRuns(syncId as string, currentPage, activeWorkspaceId);

  const handleOnSyncClick = (row: Row<SyncRunsResponse>) => {
    navigate(`run/${row.original.id}`);
  };

  const syncList = data?.data;

  const allColumns = useMemo(() => [...SyncRunsColumns], [SyncRunsColumns]);

  const handleNextPage = () => {
    setCurrentPage((prevPage) => Math.min(prevPage + 1));
  };

  const handlePrevPage = () => {
    setCurrentPage((prevPage) => Math.max(prevPage - 1, 1));
  };

  return (
    <Box width='100%' pt={'20px'}>
      {!syncList && isLoading ? (
        <Loader />
      ) : (
        <Box>
          {data?.data?.length === 0 || !data?.data ? (
            <RowsNotFound />
          ) : (
            <DataTable data={data?.data} columns={allColumns} onRowClick={handleOnSyncClick} />
          )}
          <Box display='flex' flexDirection='row-reverse' pt='10px'>
            <Pagination
              currentPage={currentPage}
              isPrevPageEnabled={data?.links?.prev != null}
              isNextPageEnabled={data?.links?.next != null}
              handleNextPage={handleNextPage}
              handlePrevPage={handlePrevPage}
            />
          </Box>
        </Box>
      )}
    </Box>
  );
};

export default SyncRuns;
